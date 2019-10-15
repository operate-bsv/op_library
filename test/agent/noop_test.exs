defmodule Agent.NoopTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: FBAgent.VM.init,
      script: File.read!("src/agent/noop.lua")
    }
  end

  test "must return the same state", ctx do
    state = %{"foo" => "bar", "baz" => "qux"}
    res = %FBAgent.Cell{script: ctx.script, params: ["foo", "bar", "baz"]}
      |> FBAgent.Cell.exec!(ctx.vm, state: state)
    assert res == state
  end

end
