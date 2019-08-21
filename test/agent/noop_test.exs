defmodule Agent.NoopTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: FB.VM.init,
      script: File.read!("src/agent/noop.lua")
    }
  end

  test "must return the same context", ctx do
    context = %{"foo" => "bar", "baz" => "qux"}
    res = %FB.Cell{script: ctx.script, params: ["foo", "bar", "baz"]}
      |> FB.Cell.exec!(ctx.vm, context: context)
    assert res == context
  end

end
