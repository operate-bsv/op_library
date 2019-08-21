defmodule Object.ExtendNewTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: FB.VM.init,
      script: File.read!("src/object/extend_new.lua")
    }
  end
  
  describe "without a context" do
    test "must set simple key value pairs", ctx do
      res = %FB.Cell{script: ctx.script, params: ["a", 1, "b", 2, "c", 3]}
      |> FB.Cell.exec!(ctx.vm)
      assert res["a"] == 1
      assert res["b"] == 2
      assert res["c"] == 3
    end

    test "wont overwrite existing keys", ctx do
      res = %FB.Cell{script: ctx.script, params: ["foo.bar", 1, "foo.baz", 2, "foo.bar.baz", 3]}
      |> FB.Cell.exec!(ctx.vm)
      assert res["foo"]["bar"] == 1
    end
  end

  describe "with a context" do
    test "must merge simple objects without overriding existing keys", ctx do
      res = %FB.Cell{script: ctx.script, params: ["a", "x", "c", "y"]}
      |> FB.Cell.exec!(ctx.vm, context: %{"a" => 1, "b" => 2})
      assert res == %{"a" => 1, "b" => 2, "c" => "y"}
    end

    test "must merge deep objects", ctx do
      res = %FB.Cell{script: ctx.script, params: ["foo.baz", "x", "foo.qux", "y"]}
      |> FB.Cell.exec!(ctx.vm, context: %{"foo" => %{"bar" => 1, "baz" => 2}})
      assert res == %{"foo" => %{"bar" => 1, "baz" => 2, "qux" => "y"}}
    end
  end
  

end
