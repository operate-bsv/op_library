defmodule Object.PutNewTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: FBAgent.VM.init,
      script: File.read!("src/object/put_new.lua")
    }
  end
  
  describe "without a state" do
    test "must set simple key value pairs with empty object on path", ctx do
      res = %FBAgent.Cell{script: ctx.script, params: ["foo", "a", 1, "b", 2]}
      |> FBAgent.Cell.exec!(ctx.vm)
      assert res == %{"foo" => [], "a" => 1, "b" => 2}
    end

#    test "wont overwrite existing keys", ctx do
#      res = %FBAgent.Cell{script: ctx.script, params: ["foo.bar", "baz.qux", 1, "baz", 3]}
#      |> FBAgent.Cell.exec!(ctx.vm)
#      assert res["foo"]["bar"]["baz"] == %{"qux" => 1}
#    end
  end

  describe "with a state" do
    test "must place the state at the path", ctx do
      res = %FBAgent.Cell{script: ctx.script, params: ["qux", "foo.bar", 3, "foo.baz", 4]}
      |> FBAgent.Cell.exec!(ctx.vm, state: %{"foo" => %{"bar" => 1, "baz" => 2}})
      assert res["qux"]["foo"] == %{"bar" => 1, "baz" => 2}
      assert res["foo"] == %{"bar" => 3, "baz" => 4}
    end

    test "wont override the new state", ctx do
      res = %FBAgent.Cell{script: ctx.script, params: ["qux", "qux.foo.bar", 5, "qux.foo.dad", 6]}
      |> FBAgent.Cell.exec!(ctx.vm, state: %{"foo" => %{"bar" => 1, "baz" => 2}})
      assert res["qux"]["foo"] == %{"bar" => 1, "baz" => 2, "dad" => 6}
    end
  end

end
