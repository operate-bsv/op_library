defmodule Agent.NoopTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: FBAgent.VM.init,
      script: File.read!("src/agent/noop.lua")
    }
  end

  test "must return the same context", ctx do
    context = %{"foo" => "bar", "baz" => "qux"}
    res = %FBAgent.Cell{script: ctx.script, params: ["foo", "bar", "baz"]}
      |> FBAgent.Cell.exec!(ctx.vm, context: context)
    assert res == context
  end

end
