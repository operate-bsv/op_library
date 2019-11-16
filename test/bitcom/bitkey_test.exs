defmodule Bitcom.BitkeyTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: Operate.VM.init,
      op: File.read!("src/bitcom/bitkey.lua")
    }
  end


  test "must set correct attributes and verify both signatures", ctx do
    params = [
      "H+g5cgN6ILgrtoxSpt25ogVkOMuC6irp8Il7e5SGVrrkC2xZMIdCNwt8TPjbIG9ZTBDrVQujT0CeRWINpXXTRHU=",
      "H+OgWIxuPUV18+FFl1sXvEQ0lZ2OsYbWf385F3ZnBPSxBo4X/2K94xuSbWwDIuD8DS4O98RywgkAzgEOxRhN6+4=",
      "644@moneybutton.com",
      "03836714653ab7b17569be03eaf6593d59116700a226a3c812cc1f3b3c8f1cbd6c"
    ]
    res = %Operate.Cell{op: ctx.op, params: params}
    |> Operate.Cell.exec!(ctx.vm)

    assert res["paymail"] == "644@moneybutton.com"
    assert res["pubkey"] == Base.decode16!("03836714653ab7b17569be03eaf6593d59116700a226a3c812cc1f3b3c8f1cbd6c", case: :lower)
    assert res["verified"] == true
  end


  test "must not verify if pubkey incorrect signatures", ctx do
    params = [
      "H+g5cgN6ILgrtoxSpt25ogVkOMuC6irp8Il7e5SGVrrkC2xZMIdCNwt8TPjbIG9ZTBDrVQujT0CeRWINpXXTRHU=",
      "H+OgWIxuPUV18+FFl1sXvEQ0lZ2OsYbWf385F3ZnBPSxBo4X/2K94xuSbWwDIuD8DS4O98RywgkAzgEOxRhN6+4=",
      "644@moneybutton.com",
      "02f6d2857cccf8cafe9c8fdb665bd710e3b8990c45857ccdefd75bbe24a20d4e62"
    ]
    res = %Operate.Cell{op: ctx.op, params: params}
    |> Operate.Cell.exec!(ctx.vm)

    assert res["verified"] == false
  end


  test "must raise when any signatures are missing", ctx do
    params = [
      nil,
      nil,
      "644@moneybutton.com", "03836714653ab7b17569be03eaf6593d59116700a226a3c812cc1f3b3c8f1cbd6c"
    ]
    assert_raise RuntimeError, ~r/^Lua Error/, fn ->
      %Operate.Cell{op: ctx.op, params: params}
      |> Operate.Cell.exec!(ctx.vm)
    end
  end

  test "must raise when pubkey is invalid", ctx do
    params = [
      "H+g5cgN6ILgrtoxSpt25ogVkOMuC6irp8Il7e5SGVrrkC2xZMIdCNwt8TPjbIG9ZTBDrVQujT0CeRWINpXXTRHU=",
      "H+OgWIxuPUV18+FFl1sXvEQ0lZ2OsYbWf385F3ZnBPSxBo4X/2K94xuSbWwDIuD8DS4O98RywgkAzgEOxRhN6+4=",
      "644@moneybutton.com",
      "abcdefghijklmn"
    ]
    assert_raise RuntimeError, ~r/^Lua Error/, fn ->
      %Operate.Cell{op: ctx.op, params: params}
      |> Operate.Cell.exec!(ctx.vm)
    end
  end

end