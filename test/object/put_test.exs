defmodule Object.PutTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: FBAgent.VM.init,
      script: File.read!("src/object/put.lua")
    }
  end
  
  describe "without a context" do
    test "must set simple key value pairs on path", ctx do
      res = %FBAgent.Cell{script: ctx.script, params: ["foo", "a", 1, "b", 2]}
      |> FBAgent.Cell.exec!(ctx.vm)
      assert res["foo"]["a"] == 1
      assert res["foo"]["b"] == 2
    end

    test "must set object on deep path", ctx do
      res = %FBAgent.Cell{script: ctx.script, params: ["foo.bar.baz", "a", 1, "b", 2]}
      |> FBAgent.Cell.exec!(ctx.vm)
      assert res["foo"]["bar"]["baz"] == %{"a" => 1, "b" => 2}
    end

    test "must overwrite existing keys", ctx do
      res = %FBAgent.Cell{script: ctx.script, params: ["foo.bar", "baz.qux", 1, "baz", 3]}
      |> FBAgent.Cell.exec!(ctx.vm)
      assert res["foo"]["bar"]["baz"] == 3
    end
  end

  describe "with a context" do
    test "must merge simple objects", ctx do
      res = %FBAgent.Cell{script: ctx.script, params: ["foo", "a", 1, "b", 2]}
      |> FBAgent.Cell.exec!(ctx.vm, context: %{"bar" => %{"a" => 1, "b" => 2}})
      assert res["foo"] == %{"a" => 1, "b" => 2}
      assert res["bar"] == %{"a" => 1, "b" => 2}
    end

    test "must merge deep objects", ctx do
      res = %FBAgent.Cell{script: ctx.script, params: ["foo.baz", "a", 1, "b", 2, "a", 3]}
      |> FBAgent.Cell.exec!(ctx.vm, context: %{"foo" => %{"bar" => 1, "baz" => 2}})
      assert res["foo"]["bar"] == 1
      assert res["foo"]["baz"] == %{"a" => 3, "b" => 2}
    end
  end

end
