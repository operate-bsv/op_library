defmodule Bitkey.SigVerifyFromTest do
  use ExUnit.Case
  alias Operate.VM

  setup_all do
    {:ok, _pid} = Operate.start_link(aliases: %{
      "13SrNDkVzY5bHBRKNu5iXTQ7K7VqTh5tJC" => "a575f641" # bitkey
    })
    %{
      vm: VM.init,
      op: File.read!("src/bitkey/sig_verify_from.lua")
    }
  end


  describe "simple example without signed content" do
    test "must set the correct attributes", ctx do
      res = %Operate.Cell{op: ctx.op, data_index: 0, params: ["##dummy_sig##", "testing@moneybutton.com"]}
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
        %Operate.Cell{op: ctx.op, params: ["##dummy_sig##", nil]}
        |> Operate.Cell.exec!(ctx.vm)
      end
    end

    test "must raise when signature is missing", ctx do
      assert_raise RuntimeError, ~r/^Lua Error/, fn ->
        %Operate.Cell{op: ctx.op, params: [nil, "testing@moneybutton.com"]}
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
      tx = File.read!("test/mocks/bitkey_sig_verify_from_tape.json")
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
      assert res["paymail"] == "libs@moneybutton.com"
      assert res["signature"] == "H05w1YSISNYzbt0mNvBtWdWInPiM+iddO6tqfxiExqe3XxRM83y6+CfQBkXILToNUcjUCWVzWi3xB9SxKI9kZ6U="
      assert VM.exec_function!(res["verify"])
    end

    test "must verify with raw signature", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      sig = <<31, 78, 112, 213, 132, 136, 72, 214, 51, 110, 221, 38, 54, 240, 109, 89, 213,
              136, 156, 248, 140, 250, 39, 93, 59, 171, 106, 127, 24, 132, 198, 167, 183,
              95, 20, 76, 243, 124, 186, 248, 39, 208, 6, 69, 200, 45, 58, 13, 81, 200, 212,
              9, 101, 115, 90, 45, 241, 7, 212, 177, 40, 143, 100, 103, 165>>

      res = ctx.tape.cells
      |> Enum.at(0)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          sig,
          "libs@moneybutton.com"
        ])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["signature"] == sig
      assert VM.exec_function!(res["verify"])
    end

    test "wont verify with different signature", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      res = ctx.tape.cells
      |> Enum.at(0)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          "H0ZSB82auZo8N8shRJ83Yi2mgp6ObHG7MFwRG/mbufq5c5xcAecgzModbLJZ04KrVqNFH7NmRMNhCvbquGGTS7I=",
          "libs@moneybutton.com"
        ])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["paymail"] == "libs@moneybutton.com"
      refute VM.exec_function!(res["verify"])
    end
  end

end