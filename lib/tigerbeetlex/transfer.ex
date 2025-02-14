defmodule TigerBeetlex.Transfer do
  use TypedStruct

  alias TigerBeetlex.Transfer
  alias TigerBeetlex.Transfer.Flags

  typedstruct do
    @typedoc "A struct representing a TigerBeetle account"

    field :id, TigerBeetlex.Types.uint128(), enforce: true
    field :debit_account_id, TigerBeetlex.Types.uint128()
    field :credit_account_id, TigerBeetlex.Types.uint128()
    field :user_data, TigerBeetlex.Types.uint128()
    field :pending_id, TigerBeetlex.Types.uint128()
    field :timeout, non_neg_integer()
    field :ledger, non_neg_integer()
    field :code, non_neg_integer()
    field :flags, non_neg_integer()
    field :amount, non_neg_integer()
    field :timestamp, non_neg_integer()
  end

  def from_binary!(<<_::binary-size(128)>> = bin) do
    <<id::binary-size(16), debit_account_id::binary-size(16), credit_account_id::binary-size(16),
      user_data::binary-size(16), _reserved::binary-size(16), pending_id::binary-size(16),
      timeout::unsigned-little-64, ledger::unsigned-little-32, code::unsigned-little-16,
      flags::unsigned-little-16, amount::unsigned-little-64, timestamp::unsigned-little-64>> = bin

    %Transfer{
      id: id,
      debit_account_id: debit_account_id,
      credit_account_id: credit_account_id,
      user_data: user_data,
      pending_id: pending_id,
      timeout: timeout,
      ledger: ledger,
      code: code,
      flags: Flags.from_u16!(flags),
      amount: amount,
      timestamp: timestamp
    }
  end
end
