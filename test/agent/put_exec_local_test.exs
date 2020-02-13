defmodule Agent.PutExecLocalTest do
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
      op: File.read!("src/agent/put_exec_local.lua")
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

    test "must return result of output on state", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["foo", 1]}
      |> Operate.Cell.exec!(ctx.vm)
      assert res["foo"]["baz"] == "qux"
    end

    test "must return result of txid on state at deep path", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["foo.bar", "2"]}
      |> Operate.Cell.exec!(ctx.vm)
      assert res["foo"]["bar"]["quux"] == "garply"
    end
  end
end
