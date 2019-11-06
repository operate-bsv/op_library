defmodule Bitcom.MAPTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: Operate.VM.init,
      op: File.read!("src/bitcom/map.lua")
    }
  end

  describe "SET without a state" do
    test "must set simple key values", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["SET", "foo.bar", 1, "foo.baz", 2]}
      |> Operate.Cell.exec!(ctx.vm)
      assert res["foo"] == %{"bar" => 1, "baz" => 2}
      assert res["_MAP"]["SET"] == %{"foo.bar" => 1, "foo.baz" => 2}
    end

    test "must omit keys when nil", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["SET", "foo.bar", 1, nil, 2]}
      |> Operate.Cell.exec!(ctx.vm)
      assert res["foo"]["bar"] == 1
      assert res["_MAP"]["SET"] == %{"foo.bar" => 1}
    end
  end

  describe "SET with a state" do
    test "must merge deep objects", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["SET", "foo.baz", "x", "foo.qux", "y"]}
      |> Operate.Cell.exec!(ctx.vm, state: %{"foo" => %{"bar" => 1, "baz" => 2}})
      assert res["foo"] == %{"bar" => 1, "baz" => "x", "qux" => "y"}
      assert res["_MAP"]["SET"] == %{"foo.baz" => "x", "foo.qux" => "y"}
    end
  end

  describe "DELETE without a state" do
    test "must put mappings onto state", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["DELETE", "foo.bar", "foo.baz"]}
      |> Operate.Cell.exec!(ctx.vm)
      assert Map.keys(res) == ["_MAP"]
      assert res["_MAP"]["DELETE"] == ["foo.bar", "foo.baz"]
    end

    test "must delete exact mappings", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["DELETE", "foo.bar", "foo.baz"]}
      |> Operate.Cell.exec!(ctx.vm, state: %{"foo" => %{"bar" => 1, "baz" => 2, "qux" => 3}})
      assert res["foo"] == %{"qux" => 3}
    end

    test "must delete entire trees", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["DELETE", "foo.bar"]}
      |> Operate.Cell.exec!(ctx.vm, state: %{"foo" => %{"bar" => %{"baz" => 2, "qux" => 3}}})
      assert res["foo"] == []
    end

    test "must ignore if path doesnt exist", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["DELETE", "foo.bar", "foo.baz.qux"]}
      |> Operate.Cell.exec!(ctx.vm, state: %{"foo" => %{"bar" => 42, "qux" => 11}})
      assert res["foo"] == %{"qux" => 11}
      assert res["_MAP"]["DELETE"] == ["foo.bar", "foo.baz.qux"]
    end
  end

end
