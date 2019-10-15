defmodule Bitcom.AIPTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: FBAgent.VM.init,
      script: File.read!("src/bitcom/aip.lua")
    }
  end


  describe "simple examples" do
    test "must set correct attributes", ctx do
      res = %FBAgent.Cell{script: ctx.script, params: ["BITCOIN_ECDSA", "1AKHViYgBGbmxi8qiJkNvoHNeDu9m3MfPE", "##computed_sig##"]}
      |> FBAgent.Cell.exec!(ctx.vm)
      |> Map.get("_AIP")
      |> List.first

      assert res["algo"] == "BITCOIN_ECDSA"
      assert res["address"] == "1AKHViYgBGbmxi8qiJkNvoHNeDu9m3MfPE"
      assert res["signature"] =="##computed_sig##"
    end

    test "must put variable length indices into list", ctx do
      res = %FBAgent.Cell{script: ctx.script, params: ["BITCOIN_ECDSA", "1AKHViYgBGbmxi8qiJkNvoHNeDu9m3MfPE", "##computed_sig##", "1", "2", "3", "6", "7"]}
      |> FBAgent.Cell.exec!(ctx.vm)
      |> Map.get("_AIP")
      |> List.first

      assert res["indices"] == [1, 2, 3, 6, 7]
    end
  end


  describe "example from AIP docs with implicit indices" do
    setup do
      tx = File.read!("test/mocks/bitcom_aip_get_tape_1.json")
      |> Jason.decode!
      |> FBAgent.Adapter.Bob.to_bpu
      |> List.first
      %{
        tx: tx,
        tape: FBAgent.Tape.from_bpu(tx)
      }
    end

    test "must verify the signature", ctx do
      cell = ctx.tape.cells
      |> Enum.at(1)
      |> Map.put(:script, ctx.script)

      vm = ctx.vm
      |> FBAgent.VM.set!("ctx.tx", ctx.tape.tx)
      |> FBAgent.VM.set!("ctx.tape_index", ctx.tape.index)

      res = FBAgent.Cell.exec!(cell, vm)
      |> Map.get("_AIP")
      |> List.first

      assert res["verified"] == true
      assert res["indices"] == []
    end
  end


  describe "example from AIP docs with explicit indices" do
    setup do
      tx = File.read!("test/mocks/bitcom_aip_get_tape_2.json")
      |> Jason.decode!
      |> FBAgent.Adapter.Bob.to_bpu
      |> List.first
      %{
        tx: tx,
        tape: FBAgent.Tape.from_bpu(tx)
      }
    end

    test "must verify the signature", ctx do
      cell = ctx.tape.cells
      |> Enum.at(2)
      |> Map.put(:script, ctx.script)

      vm = ctx.vm
      |> FBAgent.VM.set!("ctx.tx", ctx.tape.tx)
      |> FBAgent.VM.set!("ctx.tape_index", ctx.tape.index)

      res = FBAgent.Cell.exec!(cell, vm)
      |> Map.get("_AIP")
      |> List.first

      assert res["verified"] == true
      assert res["indices"] == Enum.to_list(0..18)
    end
  end

end
