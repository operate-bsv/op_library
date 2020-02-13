defmodule Agent.PutExecTest do
  use ExUnit.Case

  setup_all do
    Operate.start_link
    %{
      vm: Operate.VM.init,
      op: File.read!("src/agent/put_exec.lua")
    }
  end


  describe "Call without a state" do
    setup do
      Tesla.Mock.mock fn env ->
        cond do
          String.match?(env.url, ~r/bob.planaria.network/) ->
            File.read!("test/mocks/agent_exec_get_tape.json") |> Jason.decode! |> Tesla.Mock.json
          String.match?(env.url, ~r/api.operatebsv.org/) ->
            File.read!("test/mocks/agent_exec_get_ops.json") |> Jason.decode! |> Tesla.Mock.json
        end
      end
      :ok
    end

    test "must return result of txid on state", ctx do
      txid = "65aa086b2c54d5d792973db425b70712a708a115cd71fb67bd780e8ad9513ac9"
      res = %Operate.Cell{op: ctx.op, params: ["foo", txid]}
      |> Operate.Cell.exec!(ctx.vm)
      assert Map.keys(res["foo"]) == ["name", "numbers"]
    end

    test "must return result of txid on state at deep path", ctx do
      txid = "65aa086b2c54d5d792973db425b70712a708a115cd71fb67bd780e8ad9513ac9/0"
      res = %Operate.Cell{op: ctx.op, params: ["foo.bar", txid]}
      |> Operate.Cell.exec!(ctx.vm)
      assert Map.keys(res["foo"]["bar"]) == ["name", "numbers"]
    end

    test "must accept binary txid", ctx do
      txid = "65aa086b2c54d5d792973db425b70712a708a115cd71fb67bd780e8ad9513ac9"
      |> Base.decode16!(case: :lower)
      res = %Operate.Cell{op: ctx.op, params: ["foo", txid]}
      |> Operate.Cell.exec!(ctx.vm)
      assert Map.keys(res["foo"]) == ["name", "numbers"]
    end

    test "wont accept invalid txid", ctx do
      txid = "65aa086b"
      assert_raise RuntimeError, ~r/Invalid txid\./, fn ->
        %Operate.Cell{op: ctx.op, params: ["foo", txid]}
        |> Operate.Cell.exec!(ctx.vm)
      end
    end
  end

end
