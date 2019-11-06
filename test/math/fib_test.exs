defmodule Math.FibTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: Operate.VM.init,
      op: File.read!("src/math/fib.lua")
    }
  end
  
  test "must return correct fib sequene", ctx do
    res = %Operate.Cell{op: ctx.op, params: ["10", "100", "1000"]}
    |> Operate.Cell.exec!(ctx.vm)
    assert res == [
      55,
      354224848179261915075,
      43466557686937456435688527675040625802564660517371780402481729089536555417949051890403879840079255169295922593080322634775209689623239873322471161642996440906533187938298969649928516003704476137795166849228875
    ]
  end

  test "must ignore non numeric values", ctx do
    res = %Operate.Cell{op: ctx.op, params: ["10", "abc", "55"]}
    |> Operate.Cell.exec!(ctx.vm)
    assert res == [
      55,
      139583862445
    ]
  end

end
