defmodule Crypto.SigVerifySliceTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: Operate.VM.init,
      op: File.read!("src/crypto/sig_verify_slice.lua")
    }
  end


  describe "simple example without signed content" do
    test "must set the correct attributes", ctx do
      res = %Operate.Cell{op: ctx.op, data_index: 0, params: ["##dummy_sig##", "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw", <<1>>, <<2>>]}
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
        %Operate.Cell{op: ctx.op, params: ["##dummy_sig##", nil, <<1>>, <<2>>]}
        |> Operate.Cell.exec!(ctx.vm)
      end
    end

    test "must raise when signature is missing", ctx do
      assert_raise RuntimeError, ~r/^Lua Error/, fn ->
        %Operate.Cell{op: ctx.op, params: [nil, "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw", <<1>>, <<2>>]}
        |> Operate.Cell.exec!(ctx.vm)
      end
    end

    test "must raise when slice index is missing", ctx do
      assert_raise RuntimeError, ~r/^Lua Error/, fn ->
        %Operate.Cell{op: ctx.op, params: ["##dummy_sig##", "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw", nil, <<2>>]}
        |> Operate.Cell.exec!(ctx.vm)
      end
    end

    test "must raise when slice length is missing", ctx do
      assert_raise RuntimeError, ~r/^Lua Error/, fn ->
        %Operate.Cell{op: ctx.op, params: ["##dummy_sig##", "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw", <<1>>, nil]}
        |> Operate.Cell.exec!(ctx.vm)
      end
    end
  end


  describe "verifying a signature" do
    setup do
      tx = File.read!("test/mocks/crypto_sig_verify_slice_tape.json")
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
      |> Enum.at(2)
      |> Map.put(:op, ctx.op)
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["cell"] == 3
      assert res["hash"] == "afebc684bc475f468a7b7cac87dd04b5da4f613142003095fb6693850fac2801"
      assert res["pubkey"] == "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw"
      assert res["signature"] == "H7rets1FcfVEW7zInP5fbXogoh/3TkJmrMrArn7oK7PqWGB5o0ECAKgf2Pj8eL1fUxWv2pHBnJ5DbuSgFJ8s88Y="
      assert res["verified"] == true
    end

    test "must verify with raw signature", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      sig = <<31, 186, 222, 182, 205, 69, 113, 245, 68, 91, 188, 200, 156, 254, 95, 109,
              122, 32, 162, 31, 247, 78, 66, 102, 172, 202, 192, 174, 126, 232, 43, 179,
              234, 88, 96, 121, 163, 65, 2, 0, 168, 31, 216, 248, 252, 120, 189, 95, 83, 21,
              175, 218, 145, 193, 156, 158, 67, 110, 228, 160, 20, 159, 44, 243, 198>>

      res = ctx.tape.cells
      |> Enum.at(2)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          sig,
          "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw",
          "2",
          "6"
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
      |> Enum.at(2)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          "H7rets1FcfVEW7zInP5fbXogoh/3TkJmrMrArn7oK7PqWGB5o0ECAKgf2Pj8eL1fUxWv2pHBnJ5DbuSgFJ8s88Y=",
          pbkey,
          "2",
          "6"
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
      |> Enum.at(0)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          "H7rets1FcfVEW7zInP5fbXogoh/3TkJmrMrArn7oK7PqWGB5o0ECAKgf2Pj8eL1fUxWv2pHBnJ5DbuSgFJ8s88Y=",
          pbkey,
          "2",
          "6"
        ])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["pubkey"] == pbkey
      assert res["verified"] == true
    end

    test "must verify with binary slice range", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      res = ctx.tape.cells
      |> Enum.at(2)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          "H7rets1FcfVEW7zInP5fbXogoh/3TkJmrMrArn7oK7PqWGB5o0ECAKgf2Pj8eL1fUxWv2pHBnJ5DbuSgFJ8s88Y=",
          "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw",
          <<2>>,
          <<6>>
        ])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["verified"] == true
    end

    test "wont verify with different pubkey", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      res = ctx.tape.cells
      |> Enum.at(2)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          "H7rets1FcfVEW7zInP5fbXogoh/3TkJmrMrArn7oK7PqWGB5o0ECAKgf2Pj8eL1fUxWv2pHBnJ5DbuSgFJ8s88Y=",
          "1LFH56bwgkTLFeu53wtLdFH3L2YYQUh7yJ",
          "2",
          "6"
        ])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["pubkey"] == "1LFH56bwgkTLFeu53wtLdFH3L2YYQUh7yJ"
      assert res["verified"] == false
    end

    test "wont verify with different cell index", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      res = ctx.tape.cells
      |> Enum.at(2)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          "H7rets1FcfVEW7zInP5fbXogoh/3TkJmrMrArn7oK7PqWGB5o0ECAKgf2Pj8eL1fUxWv2pHBnJ5DbuSgFJ8s88Y=",
          "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw",
          "2",
          "5"
        ])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["verified"] == false
    end
  end

end