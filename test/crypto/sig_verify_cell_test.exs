defmodule Crypto.SigVerifyCellTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: Operate.VM.init,
      op: File.read!("src/crypto/sig_verify_cell.lua")
    }
  end


  describe "simple example without signed content" do
    test "must set the correct attributes", ctx do
      res = %Operate.Cell{op: ctx.op, data_index: 0, params: ["##dummy_sig##", "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw", <<1>>]}
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
        %Operate.Cell{op: ctx.op, params: ["##dummy_sig##", nil, <<1>>]}
        |> Operate.Cell.exec!(ctx.vm)
      end
    end

    test "must raise when signature is missing", ctx do
      assert_raise RuntimeError, ~r/^Lua Error/, fn ->
        %Operate.Cell{op: ctx.op, params: [nil, "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw", <<1>>]}
        |> Operate.Cell.exec!(ctx.vm)
      end
    end

    test "must raise when cell index is missing", ctx do
      assert_raise RuntimeError, ~r/^Lua Error/, fn ->
        %Operate.Cell{op: ctx.op, params: ["##dummy_sig##", "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw", nil]}
        |> Operate.Cell.exec!(ctx.vm)
      end
    end
  end


  describe "verifying a signature" do
    setup do
      tx = File.read!("test/mocks/crypto_sig_verify_cell_tape.json")
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
      assert res["hash"] == "b9d9129b78b2f84a1c53259ca3c57ddd7f882549380304091a568b0a26127a5d"
      assert res["pubkey"] == "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw"
      assert res["signature"] == "H8mBei7GqDDHwOgya4GL68TFOIo1DlK0k/7s5LHWEMQ7Wd1Kpi3PDMetE/5ToUJJqYKq3lz2HY6EhbNJxe3sO2M="
      assert res["verified"] == true
    end

    test "must verify with raw signature", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      sig = <<31, 201, 129, 122, 46, 198, 168, 48, 199, 192, 232, 50, 107, 129, 139, 235,
              196, 197, 56, 138, 53, 14, 82, 180, 147, 254, 236, 228, 177, 214, 16, 196, 59,
              89, 221, 74, 166, 45, 207, 12, 199, 173, 19, 254, 83, 161, 66, 73, 169, 130,
              170, 222, 92, 246, 29, 142, 132, 133, 179, 73, 197, 237, 236, 59, 99>>

      res = ctx.tape.cells
      |> Enum.at(2)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          sig,
          "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw",
          "2"
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
          "H8mBei7GqDDHwOgya4GL68TFOIo1DlK0k/7s5LHWEMQ7Wd1Kpi3PDMetE/5ToUJJqYKq3lz2HY6EhbNJxe3sO2M=",
          pbkey,
          "2"
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
          "H8mBei7GqDDHwOgya4GL68TFOIo1DlK0k/7s5LHWEMQ7Wd1Kpi3PDMetE/5ToUJJqYKq3lz2HY6EhbNJxe3sO2M=",
          pbkey,
          "2"
        ])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["pubkey"] == pbkey
      assert res["verified"] == true
    end

    test "must verify with binary cell index", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      res = ctx.tape.cells
      |> Enum.at(2)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          "H8mBei7GqDDHwOgya4GL68TFOIo1DlK0k/7s5LHWEMQ7Wd1Kpi3PDMetE/5ToUJJqYKq3lz2HY6EhbNJxe3sO2M=",
          "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw",
          <<2>>
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
          "H8mBei7GqDDHwOgya4GL68TFOIo1DlK0k/7s5LHWEMQ7Wd1Kpi3PDMetE/5ToUJJqYKq3lz2HY6EhbNJxe3sO2M=",
          "1LFH56bwgkTLFeu53wtLdFH3L2YYQUh7yJ",
          "2"
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
          "H8mBei7GqDDHwOgya4GL68TFOIo1DlK0k/7s5LHWEMQ7Wd1Kpi3PDMetE/5ToUJJqYKq3lz2HY6EhbNJxe3sO2M=",
          "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw",
          "1"
        ])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["verified"] == false
    end
  end

end