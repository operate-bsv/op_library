defmodule Bitkey.SigVerifyCellTest do
  use ExUnit.Case
  alias Operate.VM

  setup_all do
    {:ok, _pid} = Operate.start_link(aliases: %{
      "13SrNDkVzY5bHBRKNu5iXTQ7K7VqTh5tJC" => "a575f641" # bitkey
    })
    %{
      vm: VM.init,
      op: File.read!("src/bitkey/sig_verify_cell.lua")
    }
  end


  describe "simple example without signed content" do
    test "must set the correct attributes", ctx do
      res = %Operate.Cell{op: ctx.op, data_index: 0, params: ["##dummy_sig##", "testing@moneybutton.com", <<1>>]}
      |> Operate.Cell.exec!(ctx.vm)
      |> Map.get("signatures")
      |> List.first

      assert res["cell"] == 0
      assert res["signature"] == "##dummy_sig##"
      assert res["paymail"] == "testing@moneybutton.com"
      assert is_function(res["verify"])
    end

    test "must raise when paymail is missing", ctx do
      assert_raise RuntimeError, ~r/^Lua Error/, fn ->
        %Operate.Cell{op: ctx.op, params: ["##dummy_sig##", nil, <<1>>]}
        |> Operate.Cell.exec!(ctx.vm)
      end
    end

    test "must raise when signature is missing", ctx do
      assert_raise RuntimeError, ~r/^Lua Error/, fn ->
        %Operate.Cell{op: ctx.op, params: [nil, "testing@moneybutton.com", <<1>>]}
        |> Operate.Cell.exec!(ctx.vm)
      end
    end

    test "must raise when cell index is missing", ctx do
      assert_raise RuntimeError, ~r/^Lua Error/, fn ->
        %Operate.Cell{op: ctx.op, params: ["##dummy_sig##", "testing@moneybutton.com", nil]}
        |> Operate.Cell.exec!(ctx.vm)
      end
    end
  end


  describe "verifying a signature" do
    setup do
      Tesla.Mock.mock fn env ->
        cond do
          String.match?(env.url, ~r/bob.planaria.network/) ->
            File.read!("test/mocks/bitkey_get_key.json") |> Jason.decode! |> Tesla.Mock.json
          String.match?(env.url, ~r/api.operatebsv.org/) ->
            File.read!("test/mocks/bitkey_get_ops.json") |> Jason.decode! |> Tesla.Mock.json
        end
      end
      tx = File.read!("test/mocks/bitkey_sig_verify_cell_tape.json")
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
      assert res["paymail"] == "libs@moneybutton.com"
      assert res["signature"] == "H3uSMWv5Nzs/kGLm/WuPg3zcN2c45o2ZcDLMbWde8IB5IvJGGZLUr3dUX0v5IVvw/WrI0RIxYaqB1w7IL8wU7Z4="
      assert VM.exec_function!(res["verify"])
    end

    test "must verify with raw signature", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      sig = <<31, 123, 146, 49, 107, 249, 55, 59, 63, 144, 98, 230, 253, 107, 143, 131, 124, 
              220, 55, 103, 56, 230, 141, 153, 112, 50, 204, 109, 103, 94, 240, 128, 121,
              34, 242, 70, 25, 146, 212, 175, 119, 84, 95, 75, 249, 33, 91, 240, 253, 106,
              200, 209, 18, 49, 97, 170, 129, 215, 14, 200, 47, 204, 20, 237, 158>>

      res = ctx.tape.cells
      |> Enum.at(2)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          sig,
          "libs@moneybutton.com",
          "2"
        ])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["signature"] == sig
      assert VM.exec_function!(res["verify"])
    end

    test "must verify with binary cell index", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      res = ctx.tape.cells
      |> Enum.at(2)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          "H3uSMWv5Nzs/kGLm/WuPg3zcN2c45o2ZcDLMbWde8IB5IvJGGZLUr3dUX0v5IVvw/WrI0RIxYaqB1w7IL8wU7Z4=",
          "libs@moneybutton.com",
          <<2>>
        ])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert VM.exec_function!(res["verify"])
    end

    test "wont verify with different signature", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      res = ctx.tape.cells
      |> Enum.at(2)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          "H0ZSB82auZo8N8shRJ83Yi2mgp6ObHG7MFwRG/mbufq5c5xcAecgzModbLJZ04KrVqNFH7NmRMNhCvbquGGTS7I=",
          "libs@moneybutton.com",
          "2"
        ])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["paymail"] == "libs@moneybutton.com"
      refute VM.exec_function!(res["verify"])
    end

    test "wont verify with different cell index", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      res = ctx.tape.cells
      |> Enum.at(2)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          "H3uSMWv5Nzs/kGLm/WuPg3zcN2c45o2ZcDLMbWde8IB5IvJGGZLUr3dUX0v5IVvw/WrI0RIxYaqB1w7IL8wU7Z4=",
          "libs@moneybutton.com",
          "1"
        ])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      refute VM.exec_function!(res["verify"])
    end
  end

end