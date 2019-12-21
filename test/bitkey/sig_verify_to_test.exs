defmodule Bitkey.SigVerifyToTest do
  use ExUnit.Case
  alias Operate.VM

  setup_all do
    {:ok, _pid} = Operate.start_link(aliases: %{
      "13SrNDkVzY5bHBRKNu5iXTQ7K7VqTh5tJC" => "a575f641" # bitkey
    })
    %{
      vm: VM.init,
      op: File.read!("src/bitkey/sig_verify_to.lua")
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
      tx = File.read!("test/mocks/bitkey_sig_verify_to_tape.json")
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
      assert res["paymail"] == "libs@moneybutton.com"
      assert res["signature"] == "H8+GubpvseT6lfuYqgJ2VEwU4Y2zTIxQMhWq5PdiVwyoZP5wMmFS7Zr3eRHzvMSOpm8bqh0AY8P+cxaaEvVndtc="
      assert VM.exec_function!(res["verify"])
    end

    test "must verify with raw signature", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      sig = <<31, 207, 134, 185, 186, 111, 177, 228, 250, 149, 251, 152, 170, 2, 118, 84,
              76, 20, 225, 141, 179, 76, 140, 80, 50, 21, 170, 228, 247, 98, 87, 12, 168,
              100, 254, 112, 50, 97, 82, 237, 154, 247, 121, 17, 243, 188, 196, 142, 166,
              111, 27, 170, 29, 0, 99, 195, 254, 115, 22, 154, 18, 245, 103, 118, 215>>

      res = ctx.tape.cells
      |> Enum.at(1)
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
      |> Enum.at(1)
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