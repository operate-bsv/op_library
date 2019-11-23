defmodule Object.PutTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: Operate.VM.init,
      op: File.read!("src/object/put.lua")
    }
  end
  
  describe "without a state" do
    test "must set simple key value pairs on path", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["foo", "a", 1, "b", 2]}
      |> Operate.Cell.exec!(ctx.vm)
      assert res["foo"]["a"] == 1
      assert res["foo"]["b"] == 2
    end

    test "must set object on deep path", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["foo.bar.baz", "a", 1, "b", 2]}
      |> Operate.Cell.exec!(ctx.vm)
      assert res["foo"]["bar"]["baz"] == %{"a" => 1, "b" => 2}
    end

    test "must add object array", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["foo.bar[]", "a", 1, "b", 2]}
      |> Operate.Cell.exec!(ctx.vm)
      assert res["foo"]["bar"] == [%{"a" => 1, "b" => 2}]
    end

    test "must add values to arrays", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["foo.bar", "baz[]", 1, "baz[]", 2]}
      |> Operate.Cell.exec!(ctx.vm)
      assert res["foo"]["bar"]["baz"] == [1,2]
    end

    test "must overwrite existing keys", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["foo.bar", "baz.qux", 1, "baz", 3]}
      |> Operate.Cell.exec!(ctx.vm)
      assert res["foo"]["bar"]["baz"] == 3
    end
  end

  describe "with a state" do
    test "must merge simple objects", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["foo", "a", 1, "b", 2]}
      |> Operate.Cell.exec!(ctx.vm, state: %{"bar" => %{"a" => 1, "b" => 2}})
      assert res["foo"] == %{"a" => 1, "b" => 2}
      assert res["bar"] == %{"a" => 1, "b" => 2}
    end

    test "must merge deep objects", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["foo.baz", "a", 1, "b", 2, "a", 3]}
      |> Operate.Cell.exec!(ctx.vm, state: %{"foo" => %{"bar" => 1, "baz" => 2}})
      assert res["foo"]["bar"] == 1
      assert res["foo"]["baz"] == %{"a" => 3, "b" => 2}
    end
  end

end
