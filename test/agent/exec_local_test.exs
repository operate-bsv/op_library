defmodule Agent.ExecLocalTest do
  use ExUnit.Case
  alias Operate.VM

  setup_all do
    Operate.start_link

    tx = File.read!("test/mocks/agent_exec_local_tx.json")
    |> Jason.decode!
    |> Map.get("u")
    |> List.first
    |> Operate.BPU.Transaction.from_map

    vm = Operate.VM.init
    |> VM.set!("ctx.tx", tx)
    |> VM.set!("ctx.tape_index", 0)

    %{
      vm: vm,
      op: File.read!("src/agent/exec_local.lua")
    }
  end


  describe "Call without a state" do
    setup do
      Tesla.Mock.mock fn env ->
        cond do
          String.match?(env.url, ~r/api.operatebsv.org/) ->
            File.read!("test/mocks/agent_exec_local_ops.json") |> Jason.decode! |> Tesla.Mock.json
        end
      end
      :ok
    end

    test "must return the result of the given output index", ctx do
      res = %Operate.Cell{op: ctx.op, params: [1]}
      |> Operate.Cell.exec!(ctx.vm)
      assert res["baz"] == "qux"
    end

    test "must accept index as string", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["2"]}
      |> Operate.Cell.exec!(ctx.vm)
      assert res["quux"] == "garply"
    end
  end


  describe "Call with a state" do
    setup do
      Tesla.Mock.mock fn env ->
        cond do
          String.match?(env.url, ~r/api.operatebsv.org/) ->
            File.read!("test/mocks/agent_exec_local_ops.json") |> Jason.decode! |> Tesla.Mock.json
        end
      end
      :ok
    end

    test "must return the result of the given txid", ctx do
      res = %Operate.Cell{op: ctx.op, params: [1]}
      |> Operate.Cell.exec!(ctx.vm, state: %{"foo" => "bar"})
      assert res["foo"] == "bar"
      assert res["baz"] == "qux"
    end
  end
end
