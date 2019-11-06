defmodule Bitcom.HAIPTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: Operate.VM.init,
      op: File.read!("src/bitcom/haip.lua")
    }
  end


  describe "simple examples" do
    test "must set correct attributes", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["SHA256", "BITCOIN_ECDSA", "1AKHViYgBGbmxi8qiJkNvoHNeDu9m3MfPE", "##computed_sig##", <<0>>]}
      |> Operate.Cell.exec!(ctx.vm)
      |> Map.get("_HAIP")
      |> List.first

      assert res["hash_algo"] == "SHA256"
      assert res["sig_algo"] == "BITCOIN_ECDSA"
      assert res["address"] == "1AKHViYgBGbmxi8qiJkNvoHNeDu9m3MfPE"
      assert res["signature"] == "##computed_sig##"
      assert res["indices"] == []
      assert res["verified"] == false
    end

    test "must put variable length indices into list", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["SHA256", "BITCOIN_ECDSA", "1AKHViYgBGbmxi8qiJkNvoHNeDu9m3MfPE", "##computed_sig##", <<1>>, <<2, 3, 4>>]}
      |> Operate.Cell.exec!(ctx.vm)
      |> Map.get("_HAIP")
      |> List.first

      assert res["indices"] == [2, 3, 4]
    end

    test "must decode 16bit indices", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["SHA256", "BITCOIN_ECDSA", "1AKHViYgBGbmxi8qiJkNvoHNeDu9m3MfPE", "##computed_sig##", <<2>>, <<2::little-16, 3::little-16, 4::little-16>>]}
      |> Operate.Cell.exec!(ctx.vm)
      |> Map.get("_HAIP")
      |> List.first

      assert res["indices"] == [2, 3, 4]
    end
  end


  describe "example from HAIP docs with implicit indices" do
    setup do
      tx = File.read!("test/mocks/bitcom_haip_get_tape_1.json")
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
      |> Map.get("_HAIP")
      |> List.first

      assert res["verified"] == true
      assert res["hash"] == "733c8e0d921a72e1e650c16820cbcca53aac42ba98c3b27635c2dc978e11fc7f"
      assert res["indices"] == []
    end
  end


  describe "example from HAIP docs with explicit indices" do
    setup do
      tx = File.read!("test/mocks/bitcom_haip_get_tape_2.json")
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
      |> Map.get("_HAIP")
      |> List.first

      assert res["verified"] == true
      assert res["hash"] == "5fd6576f1b935089fa7799dabc05a40288e5aa2ea9215bce94e9fec4b143c633"
      assert res["indices"] == Enum.to_list(2..5)
    end
  end

end
