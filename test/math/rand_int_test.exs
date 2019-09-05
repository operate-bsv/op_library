defmodule Math.RandIntTest do
  use ExUnit.Case

  setup_all do
    %{
      # Set VM with fake txid
      vm: FB.VM.init |> Sandbox.set!("tx", %{txid: "abcdef"}),
      script: File.read!("src/math/rand_int.lua")
    }
  end
  
  test "must create n unique numbers", ctx do
    res = %FB.Cell{script: ctx.script, params: ["6", "1", "59"]}
    |> FB.Cell.exec!(ctx.vm)
    assert is_list(res)
    assert length(res) == 6
    assert Enum.uniq(res) |> length == 6
  end

  test "must raise when numbers dont give enough range", ctx do
    assert_raise RuntimeError, ~r/^Lua Error/, fn ->
      %FB.Cell{script: ctx.script, params: ["11", "1", "10"]}
      |> FB.Cell.exec!(ctx.vm)
    end
  end

end
