defmodule TigerBeetlex.AccountBatch do
  use TypedStruct

  typedstruct opaque: true do
    field :ref, reference(), enforce: true
    # TODO: we already track this internally in the resource, we should probably read the info
    # from there
    field :length, non_neg_integer(), default: 0
  end

  alias TigerBeetlex.AccountBatch
  alias TigerBeetlex.NifAdapter
  alias TigerBeetlex.Types

  @spec new(capacity :: non_neg_integer()) ::
          {:ok, t()} | Types.create_account_batch_errors()
  def new(capacity) when is_integer(capacity) and capacity > 0 do
    with {:ok, ref} <- NifAdapter.create_account_batch(capacity) do
      {:ok, %AccountBatch{ref: ref, length: 0}}
    end
  end

  @spec add_account(batch :: t(), opts :: keyword()) ::
          {:ok, t()} | Types.add_account_errors() | Types.set_function_errors()
  def add_account(%AccountBatch{} = batch, opts) do
    %AccountBatch{ref: ref, length: length} = batch

    with :ok <- NifAdapter.add_account(ref),
         :ok <- set_fields(ref, length, opts) do
      {:ok, %{batch | length: length + 1}}
    end
  end

  defp set_fields(ref, idx, opts) do
    Enum.reduce_while(opts, :ok, fn {field, value}, _acc ->
      case set_field(ref, idx, field, value) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp set_field(ref, idx, field, value) do
    set_fun(field).(ref, idx, value)
  end

  # TODO: we should have our own setters in this module, which will have guards for input data
  # and will handle stuff like providing the flags in a user-friendly way (e.g. a keyword list)
  defp set_fun(:id), do: &NifAdapter.set_account_id/3
  defp set_fun(:user_data), do: &NifAdapter.set_account_user_data/3
  defp set_fun(:ledger), do: &NifAdapter.set_account_ledger/3
  defp set_fun(:code), do: &NifAdapter.set_account_code/3
  defp set_fun(:flags), do: &NifAdapter.set_account_flags/3
end
