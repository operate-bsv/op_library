defmodule Math.RandIntTest do
  use ExUnit.Case

  setup_all do
    %{
      # Set VM with fake txid
      vm: Operate.VM.init |> Operate.VM.set!("tx", %{txid: "abcdef"}),
      op: File.read!("src/math/rand_int.lua")
    }
  end
  
  test "must create n unique numbers", ctx do
    res = %Operate.Cell{op: ctx.op, params: ["6", "1", "59"]}
    |> Operate.Cell.exec!(ctx.vm)
    assert is_list(res)
    assert length(res) == 6
    assert Enum.uniq(res) |> length == 6
  end

  test "must raise when numbers dont give enough range", ctx do
    assert_raise RuntimeError, ~r/^Lua Error/, fn ->
      %Operate.Cell{op: ctx.op, params: ["11", "1", "10"]}
      |> Operate.Cell.exec!(ctx.vm)
    end
  end

end
