defmodule Crypto.SigVerifyToTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: Operate.VM.init,
      op: File.read!("src/crypto/sig_verify_to.lua")
    }
  end


  describe "simple example without signed content" do
    test "must set the correct attributes", ctx do
      res = %Operate.Cell{op: ctx.op, data_index: 0, params: ["##dummy_sig##", "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw"]}
      |> Operate.Cell.exec!(ctx.vm)
      |> Map.get("signatures")
      |> List.first

      assert res["cell"] == 0
      assert res["signature"] == "##dummy_sig##"
      assert res["pubkey"] == "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw"
      assert res["verified"] == false
    end

    test "must raise when pubkey is missing", ctx do
      assert_raise RuntimeError, ~r/^Lua Error/, fn ->
        %Operate.Cell{op: ctx.op, params: ["##dummy_sig##", nil]}
        |> Operate.Cell.exec!(ctx.vm)
      end
    end

    test "must raise when signature is missing", ctx do
      assert_raise RuntimeError, ~r/^Lua Error/, fn ->
        %Operate.Cell{op: ctx.op, params: [nil, "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw"]}
        |> Operate.Cell.exec!(ctx.vm)
      end
    end
  end


  describe "verifying a signature" do
    setup do
      tx = File.read!("test/mocks/crypto_sig_verify_to_tape.json")
      |> Jason.decode!
      |> Operate.BPU.Transaction.from_map
      %{
        tape: Operate.Tape.from_bpu!(tx)
      }
    end

    test "must verify a correct signature", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      res = ctx.tape.cells
      |> Enum.at(1)
      |> Map.put(:op, ctx.op)
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["cell"] == 2
      assert res["hash"] == "03c1ccb5143e51a82ff46d65a034540ea1d084dbf2635828b0514a486e0a7952"
      assert res["pubkey"] == "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw"
      assert res["signature"] == "H0ZSB82auZo8N8shRJ83Yi2mgp6ObHG7MFwRG/mbufq5c5xcAecgzModbLJZ04KrVqNFH7NmRMNhCvbquGGTS7I="
      assert res["verified"] == true
    end

    test "must verify with raw signature", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      sig = <<31, 70, 82, 7, 205, 154, 185, 154, 60, 55, 203, 33, 68, 159, 55, 98, 45, 166,
              130, 158, 142, 108, 113, 187, 48, 92, 17, 27, 249, 155, 185, 250, 185, 115,
              156, 92, 1, 231, 32, 204, 202, 29, 108, 178, 89, 211, 130, 171, 86, 163, 69,
              31, 179, 102, 68, 195, 97, 10, 246, 234, 184, 97, 147, 75, 178>>

      res = ctx.tape.cells
      |> Enum.at(1)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          sig,
          "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw"
        ])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["signature"] == sig
      assert res["verified"] == true
    end

    test "must verify with raw public key", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      pbkey = <<2, 109, 186, 127, 25, 192, 58, 202, 83, 145, 224, 117, 226, 188, 158, 20,
                131, 215, 165, 252, 184, 165, 133, 5, 206, 78, 198, 16, 142, 2, 230, 20, 97>>

      res = ctx.tape.cells
      |> Enum.at(1)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          "H0ZSB82auZo8N8shRJ83Yi2mgp6ObHG7MFwRG/mbufq5c5xcAecgzModbLJZ04KrVqNFH7NmRMNhCvbquGGTS7I=",
          pbkey
        ])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["pubkey"] == pbkey
      assert res["verified"] == true
    end

    test "must verify with hex public key", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      pbkey = "026dba7f19c03aca5391e075e2bc9e1483d7a5fcb8a58505ce4ec6108e02e61461"

      res = ctx.tape.cells
      |> Enum.at(1)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          "H0ZSB82auZo8N8shRJ83Yi2mgp6ObHG7MFwRG/mbufq5c5xcAecgzModbLJZ04KrVqNFH7NmRMNhCvbquGGTS7I=",
          pbkey
        ])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["pubkey"] == pbkey
      assert res["verified"] == true
    end

    test "wont verify with different pubkey", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      res = ctx.tape.cells
      |> Enum.at(1)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          "H0ZSB82auZo8N8shRJ83Yi2mgp6ObHG7MFwRG/mbufq5c5xcAecgzModbLJZ04KrVqNFH7NmRMNhCvbquGGTS7I=",
          "1LFH56bwgkTLFeu53wtLdFH3L2YYQUh7yJ"
        ])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["pubkey"] == "1LFH56bwgkTLFeu53wtLdFH3L2YYQUh7yJ"
      assert res["verified"] == false
    end
  end

end