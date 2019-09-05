defmodule Object.PutNewTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: FB.VM.init,
      script: File.read!("src/object/put_new.lua")
    }
  end
  
  describe "without a context" do
    test "must set simple key value pairs with empty object on path", ctx do
      res = %FB.Cell{script: ctx.script, params: ["foo", "a", 1, "b", 2]}
      |> FB.Cell.exec!(ctx.vm)
      assert res == %{"foo" => [], "a" => 1, "b" => 2}
    end

#    test "wont overwrite existing keys", ctx do
#      res = %FB.Cell{script: ctx.script, params: ["foo.bar", "baz.qux", 1, "baz", 3]}
#      |> FB.Cell.exec!(ctx.vm)
#      assert res["foo"]["bar"]["baz"] == %{"qux" => 1}
#    end
  end

  describe "with a context" do
    test "must place the context at the path", ctx do
      res = %FB.Cell{script: ctx.script, params: ["qux", "foo.bar", 3, "foo.baz", 4]}
      |> FB.Cell.exec!(ctx.vm, context: %{"foo" => %{"bar" => 1, "baz" => 2}})
      assert res["qux"]["foo"] == %{"bar" => 1, "baz" => 2}
      assert res["foo"] == %{"bar" => 3, "baz" => 4}
    end

    test "wont override the new context", ctx do
      res = %FB.Cell{script: ctx.script, params: ["qux", "qux.foo.bar", 5, "qux.foo.dad", 6]}
      |> FB.Cell.exec!(ctx.vm, context: %{"foo" => %{"bar" => 1, "baz" => 2}})
      assert res["qux"]["foo"] == %{"bar" => 1, "baz" => 2, "dad" => 6}
    end
  end

end
