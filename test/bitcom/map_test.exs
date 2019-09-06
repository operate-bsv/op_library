defmodule Bitcom.MAPTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: FBAgent.VM.init,
      script: File.read!("src/bitcom/map.lua")
    }
  end

  describe "SET without a context" do
    test "must set simple key values", ctx do
      res = %FBAgent.Cell{script: ctx.script, params: ["SET", "foo.bar", 1, "foo.baz", 2]}
      |> FBAgent.Cell.exec!(ctx.vm)
      assert res["foo"] == %{"bar" => 1, "baz" => 2}
      assert res["_MAP"]["SET"] == %{"foo.bar" => 1, "foo.baz" => 2}
    end

    test "must omit keys when nil", ctx do
      res = %FBAgent.Cell{script: ctx.script, params: ["SET", "foo.bar", 1, nil, 2]}
      |> FBAgent.Cell.exec!(ctx.vm)
      assert res["foo"]["bar"] == 1
      assert res["_MAP"]["SET"] == %{"foo.bar" => 1}
    end
  end

  describe "SET with a context" do
    test "must merge deep objects", ctx do
      res = %FBAgent.Cell{script: ctx.script, params: ["SET", "foo.baz", "x", "foo.qux", "y"]}
      |> FBAgent.Cell.exec!(ctx.vm, context: %{"foo" => %{"bar" => 1, "baz" => 2}})
      assert res["foo"] == %{"bar" => 1, "baz" => "x", "qux" => "y"}
      assert res["_MAP"]["SET"] == %{"foo.baz" => "x", "foo.qux" => "y"}
    end
  end

  describe "DELETE without a context" do
    test "must put mappings onto context", ctx do
      res = %FBAgent.Cell{script: ctx.script, params: ["DELETE", "foo.bar", "foo.baz"]}
      |> FBAgent.Cell.exec!(ctx.vm)
      assert Map.keys(res) == ["_MAP"]
      assert res["_MAP"]["DELETE"] == ["foo.bar", "foo.baz"]
    end

    test "must delete exact mappings", ctx do
      res = %FBAgent.Cell{script: ctx.script, params: ["DELETE", "foo.bar", "foo.baz"]}
      |> FBAgent.Cell.exec!(ctx.vm, context: %{"foo" => %{"bar" => 1, "baz" => 2, "qux" => 3}})
      assert res["foo"] == %{"qux" => 3}
    end

    test "must delete entire trees", ctx do
      res = %FBAgent.Cell{script: ctx.script, params: ["DELETE", "foo.bar"]}
      |> FBAgent.Cell.exec!(ctx.vm, context: %{"foo" => %{"bar" => %{"baz" => 2, "qux" => 3}}})
      assert res["foo"] == []
    end

    test "must ignore if path doesnt exist", ctx do
      res = %FBAgent.Cell{script: ctx.script, params: ["DELETE", "foo.bar", "foo.baz.qux"]}
      |> FBAgent.Cell.exec!(ctx.vm, context: %{"foo" => %{"bar" => 42, "qux" => 11}})
      assert res["foo"] == %{"qux" => 11}
      assert res["_MAP"]["DELETE"] == ["foo.bar", "foo.baz.qux"]
    end
  end

end
