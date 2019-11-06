defmodule Bitcom.AIPTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: Operate.VM.init,
      op: File.read!("src/bitcom/aip.lua")
    }
  end


  describe "simple examples" do
    test "must set correct attributes", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["BITCOIN_ECDSA", "1AKHViYgBGbmxi8qiJkNvoHNeDu9m3MfPE", "##computed_sig##"]}
      |> Operate.Cell.exec!(ctx.vm)
      |> Map.get("_AIP")
      |> List.first

      assert res["algo"] == "BITCOIN_ECDSA"
      assert res["address"] == "1AKHViYgBGbmxi8qiJkNvoHNeDu9m3MfPE"
      assert res["signature"] =="##computed_sig##"
      assert res["indices"] == []
      assert res["verified"] == false
    end

    test "must put variable length indices into list", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["BITCOIN_ECDSA", "1AKHViYgBGbmxi8qiJkNvoHNeDu9m3MfPE", "##computed_sig##", "1", "2", "3", "6", "7"]}
      |> Operate.Cell.exec!(ctx.vm)
      |> Map.get("_AIP")
      |> List.first

      assert res["indices"] == [1, 2, 3, 6, 7]
    end
  end


  describe "example from AIP docs with implicit indices" do
    setup do
      tx = File.read!("test/mocks/bitcom_aip_get_tape_1.json")
      |> Jason.decode!
      |> Operate.Adapter.Bob.to_bpu
      |> List.first
      %{
        tx: tx,
        tape: Operate.Tape.from_bpu!(tx)
      }
    end

    test "must verify the signature", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      res = ctx.tape.cells
      |> Enum.at(1)
      |> Map.put(:op, ctx.op)
      |> Operate.Cell.exec!(vm)
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
      |> Operate.Adapter.Bob.to_bpu
      |> List.first
      %{
        tx: tx,
        tape: Operate.Tape.from_bpu!(tx)
      }
    end

    test "must verify the signature", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      res = ctx.tape.cells
      |> Enum.at(2)
      |> Map.put(:op, ctx.op)
      |> Operate.Cell.exec!(vm)
      |> Map.get("_AIP")
      |> List.first

      assert res["verified"] == true
      assert res["indices"] == Enum.to_list(0..18)
    end
  end

end
