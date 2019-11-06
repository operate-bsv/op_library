defmodule Object.ExtendNewTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: Operate.VM.init,
      op: File.read!("src/object/extend_new.lua")
    }
  end
  
  describe "without a state" do
    test "must set simple key value pairs", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["a", 1, "b", 2, "c", 3]}
      |> Operate.Cell.exec!(ctx.vm)
      assert res["a"] == 1
      assert res["b"] == 2
      assert res["c"] == 3
    end

    test "wont overwrite existing keys", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["foo.bar", 1, "foo.baz", 2, "foo.bar.baz", 3]}
      |> Operate.Cell.exec!(ctx.vm)
      assert res["foo"]["bar"] == 1
    end
  end

  describe "with a state" do
    test "must merge simple objects without overriding existing keys", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["a", "x", "c", "y"]}
      |> Operate.Cell.exec!(ctx.vm, state: %{"a" => 1, "b" => 2})
      assert res == %{"a" => 1, "b" => 2, "c" => "y"}
    end

    test "must merge deep objects", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["foo.baz", "x", "foo.qux", "y"]}
      |> Operate.Cell.exec!(ctx.vm, state: %{"foo" => %{"bar" => 1, "baz" => 2}})
      assert res == %{"foo" => %{"bar" => 1, "baz" => 2, "qux" => "y"}}
    end
  end
  

end
