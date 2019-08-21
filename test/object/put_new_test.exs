defmodule Object.PutNewTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: FB.VM.init,
      script: File.read!("src/object/put_new.lua")
    }
  end
  
  describe "without a context" do
    test "must set simple key value pairs on path", ctx do
      res = %FB.Cell{script: ctx.script, params: ["foo", "a", 1, "b", 2]}
      |> FB.Cell.exec!(ctx.vm)
      assert res["foo"]["a"] == 1
      assert res["foo"]["b"] == 2
    end

    test "wont overwrite existing keys", ctx do
      res = %FB.Cell{script: ctx.script, params: ["foo.bar", "baz.qux", 1, "baz", 3]}
      |> FB.Cell.exec!(ctx.vm)
      assert res["foo"]["bar"]["baz"] == %{"qux" => 1}
    end
  end

  describe "with a context" do
    test "wont overwrite context", ctx do
      res = %FB.Cell{script: ctx.script, params: ["foo.baz", "a", 1, "b", 2, "a", 3]}
      |> FB.Cell.exec!(ctx.vm, context: %{"foo" => %{"bar" => 1, "baz" => 2}})
      assert res["foo"]["bar"] == 1
      assert res["foo"]["baz"] == 2
    end
  end

end
