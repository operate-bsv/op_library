defmodule Agent.NoopTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: Operate.VM.init,
      op: File.read!("src/agent/noop.lua")
    }
  end

  test "must return the same state", ctx do
    state = %{"foo" => "bar", "baz" => "qux"}
    res = %Operate.Cell{op: ctx.op, params: ["foo", "bar", "baz"]}
      |> Operate.Cell.exec!(ctx.vm, state: state)
    assert res == state
  end

end
