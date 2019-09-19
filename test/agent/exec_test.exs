defmodule Agent.ExecTest do
  use ExUnit.Case

  setup_all do
    FBAgent.start_link
    %{
      vm: FBAgent.VM.init,
      script: File.read!("src/agent/exec.lua")
    }
  end


  describe "Call without a context" do
    setup do
      Tesla.Mock.mock fn env ->
        cond do
          String.match?(env.url, ~r/bob.planaria.network/) ->
            File.read!("test/mocks/agent_exec_get_tape.json") |> Jason.decode! |> Tesla.Mock.json
          String.match?(env.url, ~r/functions.chronoslabs.net/) ->
            File.read!("test/mocks/agent_exec_get_procs.json") |> Jason.decode! |> Tesla.Mock.json
        end
      end
      :ok
    end

    test "must return the result of the given txid", ctx do
      txid = "c081e7158d76b6962ecbd3b51182aac249615743574464aa3b96fce4a998858d"
      res = %FBAgent.Cell{script: ctx.script, params: [txid]}
      |> FBAgent.Cell.exec!(ctx.vm)
      assert Map.keys(res) == ["name", "numbers"]
    end

    test "must accept binary txid", ctx do
      txid = "c081e7158d76b6962ecbd3b51182aac249615743574464aa3b96fce4a998858d"
      |> Base.decode16!(case: :lower)
      res = %FBAgent.Cell{script: ctx.script, params: [txid]}
      |> FBAgent.Cell.exec!(ctx.vm)
      assert Map.keys(res) == ["name", "numbers"]
    end
  end


  describe "Call with a context" do
    setup do
      Tesla.Mock.mock fn env ->
        cond do
          String.match?(env.url, ~r/bob.planaria.network/) ->
            File.read!("test/mocks/agent_exec_get_tape.json") |> Jason.decode! |> Tesla.Mock.json
          String.match?(env.url, ~r/functions.chronoslabs.net/) ->
            File.read!("test/mocks/agent_exec_get_procs.json") |> Jason.decode! |> Tesla.Mock.json
        end
      end
      :ok
    end

    test "must return the result of the given txid", ctx do
      txid = "c081e7158d76b6962ecbd3b51182aac249615743574464aa3b96fce4a998858d"
      res = %FBAgent.Cell{script: ctx.script, params: [txid]}
      |> FBAgent.Cell.exec!(ctx.vm, context: ["testing123"])
      assert List.first(res["numbers"]) == "testing123"
    end
  end
end
