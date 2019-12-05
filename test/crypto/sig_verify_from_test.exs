defmodule Crypto.SigVerifyFromTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: Operate.VM.init,
      op: File.read!("src/crypto/sig_verify_from.lua")
    }
  end


  describe "simple example withour signed content" do
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
      tx = File.read!("test/mocks/crypto_sig_verify_from_tape.json")
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
      |> Enum.at(0)
      |> Map.put(:op, ctx.op)
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["cell"] == 1
      assert res["hash"] == "3fa2f0e6ed5f72c78f8cb90142ece18f4d210f282740cfeba6bc9363b76ea5df"
      assert res["pubkey"] == "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw"
      assert res["signature"] == "IEfsOwm4+k05NDCXLr96KB0DPGJZY66dQrTvt/4XB1yXBPF726E2RVSfWa1GcliprPXCVQeakEv6NUEBPKHBcYQ="
      assert res["verified"] == true
    end

    test "must verify with raw signature", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      sig = <<32, 71, 236, 59, 9, 184, 250, 77, 57, 52, 48, 151, 46, 191, 122, 40, 29, 3,
              60, 98, 89, 99, 174, 157, 66, 180, 239, 183, 254, 23, 7, 92, 151, 4, 241, 123,
              219, 161, 54, 69, 84, 159, 89, 173, 70, 114, 88, 169, 172, 245, 194, 85, 7,
              154, 144, 75, 250, 53, 65, 1, 60, 161, 193, 113, 132>>

      res = ctx.tape.cells
      |> Enum.at(0)
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
      |> Enum.at(0)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          "IEfsOwm4+k05NDCXLr96KB0DPGJZY66dQrTvt/4XB1yXBPF726E2RVSfWa1GcliprPXCVQeakEv6NUEBPKHBcYQ=",
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
      |> Enum.at(0)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          "IEfsOwm4+k05NDCXLr96KB0DPGJZY66dQrTvt/4XB1yXBPF726E2RVSfWa1GcliprPXCVQeakEv6NUEBPKHBcYQ=",
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
      |> Enum.at(0)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, ["IEfsOwm4+k05NDCXLr96KB0DPGJZY66dQrTvt/4XB1yXBPF726E2RVSfWa1GcliprPXCVQeakEv6NUEBPKHBcYQ=", "1LFH56bwgkTLFeu53wtLdFH3L2YYQUh7yJ"])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["pubkey"] == "1LFH56bwgkTLFeu53wtLdFH3L2YYQUh7yJ"
      assert res["verified"] == false
    end
  end

end