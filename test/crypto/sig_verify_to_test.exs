defmodule Crypto.SigVerifyToTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: Operate.VM.init,
      op: File.read!("src/crypto/sig_verify_to.lua")
    }
  end


  describe "simple example withour signed content" do
    test "must set the correct attributes", ctx do
      res = %Operate.Cell{op: ctx.op, data_index: 0, params: ["##dummy_sig##", "1Gvf1GupKwALrNiuw9tHoQg28rP5bPHLCg"]}
      |> Operate.Cell.exec!(ctx.vm)
      |> Map.get("signatures")
      |> List.first

      assert res["cell"] == 0
      assert res["signature"] == "##dummy_sig##"
      assert res["pubkey"] == "1Gvf1GupKwALrNiuw9tHoQg28rP5bPHLCg"
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
        %Operate.Cell{op: ctx.op, params: [nil, "1Gvf1GupKwALrNiuw9tHoQg28rP5bPHLCg"]}
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
      assert res["pubkey"] == "1Gvf1GupKwALrNiuw9tHoQg28rP5bPHLCg"
      assert res["signature"] == "HxaO8kU3zH0zEtGJjtk71fw5RKx9mAB7ywjKCgvKkL40Mo6xTpYhyKYQshnC05BIA4Ulor1bsgIPKp2trrTr5Nw="
      assert res["verified"] == true
    end

    test "must verify with raw public key", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      res = ctx.tape.cells
      |> Enum.at(1)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          "HxaO8kU3zH0zEtGJjtk71fw5RKx9mAB7ywjKCgvKkL40Mo6xTpYhyKYQshnC05BIA4Ulor1bsgIPKp2trrTr5Nw=",
          <<2, 246, 210, 133, 124, 204, 248, 202, 254, 156, 143, 219, 102, 91, 215, 16,
          227, 184, 153, 12, 69, 133, 124, 205, 239, 215, 91, 190, 36, 162, 13, 78, 98>>
        ])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["pubkey"] == <<2, 246, 210, 133, 124, 204, 248, 202, 254, 156, 143, 219, 102, 91, 215, 16,
                              227, 184, 153, 12, 69, 133, 124, 205, 239, 215, 91, 190, 36, 162, 13, 78, 98>>
      assert res["verified"] == true
    end

    test "must verify with hex public key", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      res = ctx.tape.cells
      |> Enum.at(1)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          "HxaO8kU3zH0zEtGJjtk71fw5RKx9mAB7ywjKCgvKkL40Mo6xTpYhyKYQshnC05BIA4Ulor1bsgIPKp2trrTr5Nw=",
          "02f6d2857cccf8cafe9c8fdb665bd710e3b8990c45857ccdefd75bbe24a20d4e62"
        ])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["pubkey"] == "02f6d2857cccf8cafe9c8fdb665bd710e3b8990c45857ccdefd75bbe24a20d4e62"
      assert res["verified"] == true
    end

    test "wont verify with different pubkey", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      res = ctx.tape.cells
      |> Enum.at(1)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, ["HxaO8kU3zH0zEtGJjtk71fw5RKx9mAB7ywjKCgvKkL40Mo6xTpYhyKYQshnC05BIA4Ulor1bsgIPKp2trrTr5Nw=", "1LFH56bwgkTLFeu53wtLdFH3L2YYQUh7yJ"])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["pubkey"] == "1LFH56bwgkTLFeu53wtLdFH3L2YYQUh7yJ"
      assert res["verified"] == false
    end
  end

end