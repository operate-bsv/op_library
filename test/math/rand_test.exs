defmodule Math.RandTest do
  use ExUnit.Case

  setup_all do
    %{
      # Set VM with fake txid
      vm: Operate.VM.init |> Operate.VM.set!("tx", %{txid: "abcdef"}),
      op: File.read!("src/math/rand.lua")
    }
  end
  
  test "must create n unique numbers", ctx do
    res = %Operate.Cell{op: ctx.op, params: ["6"]}
    |> Operate.Cell.exec!(ctx.vm)
    assert is_list(res)
    assert length(res) == 6
    assert Enum.uniq(res) |> length == 6
  end

  test "must create 1 random number of no params given", ctx do
    res = %Operate.Cell{op: ctx.op, params: []}
    |> Operate.Cell.exec!(ctx.vm)
    assert length(res) == 1
  end

end
