const std = @import("std");
const assert = std.testing.assert;

const batch = @import("batch.zig");
const beam = @import("beam");
const beam_extras = @import("beam_extras.zig");
const e = @import("erl_nif");
const resource_types = @import("resource_types.zig");

pub const IdBatch = batch.Batch(u128);

pub fn create(env: beam.env, argc: c_int, argv: [*c]const beam.term) callconv(.C) beam.term {
    if (argc != 1) unreachable;

    const args = @ptrCast([*]const beam.term, argv)[0..@intCast(usize, argc)];

    const capacity: u32 = beam.get_u32(env, args[0]) catch
        return beam.raise_function_clause_error(env);

    return batch.create(u128, env, capacity);
}

pub fn add_id(env: beam.env, argc: c_int, argv: [*c]const beam.term) callconv(.C) beam.term {
    // We don't use beam.add_item since we increase len and directly add the id in a single call
    if (argc != 2) unreachable;

    const args = @ptrCast([*]const beam.term, argv)[0..@intCast(usize, argc)];

    const id = beam_extras.get_u128(env, args[1]) catch
        return beam.raise_function_clause_error(env);

    const resource_type = resource_types.id_batch;
    const id_batch = beam_extras.resource_ptr(IdBatch, env, resource_type, args[0]) catch |err|
        switch (err) {
        error.FetchError => return beam.make_error_atom(env, "invalid_batch"),
    };

    {
        if (!id_batch.mutex.tryLock()) {
            return e.enif_schedule_nif(env, "add_id", 0, add_id, argc, argv);
        }
        defer id_batch.mutex.unlock();

        if (id_batch.len + 1 > id_batch.items.len) {
            return beam.make_error_atom(env, "batch_full");
        }
        id_batch.len += 1;
        id_batch.items[id_batch.len - 1] = id;
    }

    return beam.make_ok(env);
}

pub fn set_id(env: beam.env, argc: c_int, argv: [*c]const beam.term) callconv(.C) beam.term {
    if (argc != 3) unreachable;

    const args = @ptrCast([*]const beam.term, argv)[0..@intCast(usize, argc)];

    const resource_type = resource_types.id_batch;
    const id_batch = beam_extras.resource_ptr(IdBatch, env, resource_type, args[0]) catch |err|
        switch (err) {
        error.FetchError => return beam.make_error_atom(env, "invalid_batch"),
    };

    const idx: u32 = beam.get_u32(env, args[1]) catch
        return beam.raise_function_clause_error(env);

    {
        if (!id_batch.mutex.tryLock()) {
            return e.enif_schedule_nif(env, "set_id", 0, set_id, argc, argv);
        }
        defer id_batch.mutex.unlock();

        if (idx >= id_batch.len) {
            return beam.make_error_atom(env, "out_of_bounds");
        }

        const id = beam_extras.get_u128(env, args[2]) catch
            return beam.raise_function_clause_error(env);

        id_batch.items[idx] = id;
    }

    return beam.make_ok(env);
}
