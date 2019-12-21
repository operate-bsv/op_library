defmodule Bitkey.SigVerifySliceTest do
  use ExUnit.Case
  alias Operate.VM

  setup_all do
    {:ok, _pid} = Operate.start_link(aliases: %{
      "13SrNDkVzY5bHBRKNu5iXTQ7K7VqTh5tJC" => "a575f641" # bitkey
    })
    %{
      vm: VM.init,
      op: File.read!("src/bitkey/sig_verify_slice.lua")
    }
  end


  describe "simple example without signed content" do
    test "must set the correct attributes", ctx do
      res = %Operate.Cell{op: ctx.op, data_index: 0, params: ["##dummy_sig##", "testing@moneybutton.com", <<1>>, <<2>>]}
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
        %Operate.Cell{op: ctx.op, params: ["##dummy_sig##", nil, <<1>>, <<2>>]}
        |> Operate.Cell.exec!(ctx.vm)
      end
    end

    test "must raise when signature is missing", ctx do
      assert_raise RuntimeError, ~r/^Lua Error/, fn ->
        %Operate.Cell{op: ctx.op, params: [nil, "testing@moneybutton.com", <<1>>, <<2>>]}
        |> Operate.Cell.exec!(ctx.vm)
      end
    end

    test "must raise when slice index is missing", ctx do
      assert_raise RuntimeError, ~r/^Lua Error/, fn ->
        %Operate.Cell{op: ctx.op, params: ["##dummy_sig##", "testing@moneybutton.com", nil, <<2>>]}
        |> Operate.Cell.exec!(ctx.vm)
      end
    end

    test "must raise when slice length is missing", ctx do
      assert_raise RuntimeError, ~r/^Lua Error/, fn ->
        %Operate.Cell{op: ctx.op, params: ["##dummy_sig##", "testing@moneybutton.com", <<1>>, nil]}
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
      tx = File.read!("test/mocks/bitkey_sig_verify_slice_tape.json")
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
      assert res["paymail"] == "libs@moneybutton.com"
      assert res["signature"] == "H2f53xeeBVpHvMJaUPNhvNlW3YarjqX8C7DGGgIMR6deU5ijm41PT2BXUynAymmm20ktbeAalCpsdGUON7jJ24w="
      assert VM.exec_function!(res["verify"])
    end

    test "must verify with raw signature", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      sig = <<31, 103, 249, 223, 23, 158, 5, 90, 71, 188, 194, 90, 80, 243, 97, 188, 217,
              86, 221, 134, 171, 142, 165, 252, 11, 176, 198, 26, 2, 12, 71, 167, 94, 83,
              152, 163, 155, 141, 79, 79, 96, 87, 83, 41, 192, 202, 105, 166, 219, 73, 45,
              109, 224, 26, 148, 42, 108, 116, 101, 14, 55, 184, 201, 219, 140>>

      res = ctx.tape.cells
      |> Enum.at(2)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          sig,
          "libs@moneybutton.com",
          "2",
          "6"
        ])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      assert res["signature"] == sig
      assert VM.exec_function!(res["verify"])
    end

    test "must verify with binary slice range", ctx do
      vm = ctx.vm
      |> Operate.VM.set!("ctx.tx", ctx.tape.tx)
      |> Operate.VM.set!("ctx.tape_index", ctx.tape.index)

      res = ctx.tape.cells
      |> Enum.at(2)
      |> Map.put(:op, ctx.op)
      |> Map.put(:params, [
          "H2f53xeeBVpHvMJaUPNhvNlW3YarjqX8C7DGGgIMR6deU5ijm41PT2BXUynAymmm20ktbeAalCpsdGUON7jJ24w=",
          "libs@moneybutton.com",
          <<2>>,
          <<6>>
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
          "2",
          "6"
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
          "H2f53xeeBVpHvMJaUPNhvNlW3YarjqX8C7DGGgIMR6deU5ijm41PT2BXUynAymmm20ktbeAalCpsdGUON7jJ24w=",
          "libs@moneybutton.com",
          "2",
          "5"
        ])
      |> Operate.Cell.exec!(vm)
      |> Map.get("signatures")
      |> List.first

      refute VM.exec_function!(res["verify"])
    end

  end

end