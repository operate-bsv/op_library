defmodule Object.PutNewTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: Operate.VM.init,
      op: File.read!("src/object/put_new.lua")
    }
  end
  
  describe "without a state" do
    test "must set simple key value pairs with empty object on path", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["foo", "a", 1, "b", 2]}
      |> Operate.Cell.exec!(ctx.vm)
      assert res == %{"foo" => [], "a" => 1, "b" => 2}
    end

    test "must add values to arrays", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["foo.bar", "baz[]", 1, "baz[]", 2]}
      |> Operate.Cell.exec!(ctx.vm)
      assert res["foo"]["bar"] == []
      assert res["baz"] == [1,2]
    end

    test "wont overwrite existing keys", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["foo.bar", "baz.qux", 1, "baz", 3]}
      |> Operate.Cell.exec!(ctx.vm)
      assert res["foo"]["bar"] == []
      assert res["baz"] == %{"qux" => 1}
    end
  end

  describe "with a state" do
    test "must place the state at the path", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["qux", "foo.bar", 3, "foo.baz", 4]}
      |> Operate.Cell.exec!(ctx.vm, state: %{"foo" => %{"bar" => 1, "baz" => 2}})
      assert res["qux"]["foo"] == %{"bar" => 1, "baz" => 2}
      assert res["foo"] == %{"bar" => 3, "baz" => 4}
    end

    test "must add state to array", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["qux[]", "a", 1, "b", 2]}
      |> Operate.Cell.exec!(ctx.vm, state: %{"foo" => %{"bar" => 1, "baz" => 2}})
      assert res["qux"] == [%{"foo" => %{"bar" => 1, "baz" => 2}}]
      assert res["a"] == 1
      assert res["b"] == 2
    end

    test "wont override the new state", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["qux", "qux.foo.bar", 5, "qux.foo.dad", 6]}
      |> Operate.Cell.exec!(ctx.vm, state: %{"foo" => %{"bar" => 1, "baz" => 2}})
      assert res["qux"]["foo"] == %{"bar" => 1, "baz" => 2, "dad" => 6}
    end
  end

end
