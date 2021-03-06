defmodule Bitcom.BTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: Operate.VM.init,
      op: File.read!("src/bitcom/b.lua")
    }
  end
  
  test "must create a file object", ctx do
    file = %Operate.Cell{op: ctx.op, params: ["hello world", "text/plain", "utf8", "test.txt"]}
    |> Operate.Cell.exec!(ctx.vm)
    assert file["data"] == "hello world"
    assert file["type"] == "text/plain"
    assert file["encoding"] == "utf8"
    assert file["name"] == "test.txt"
  end

  test "must default text files to utf8 encoding", ctx do
    file = %Operate.Cell{op: ctx.op, params: ["hello world", "text/plain", nil, "test.txt"]}
    |> Operate.Cell.exec!(ctx.vm)
    assert file["encoding"] == "utf8"
  end

  test "wont default non text files to utf8 encoding", ctx do
    file = %Operate.Cell{op: ctx.op, params: ["hello world", "image/png", nil, "test.png"]}
    |> Operate.Cell.exec!(ctx.vm)
    assert file["encoding"] != "utf8"
  end

  test "must handle missing attributes", ctx do
    file = %Operate.Cell{op: ctx.op, params: ["hello world", nil, nil, ""]}
    |> Operate.Cell.exec!(ctx.vm)
    assert file == %{"data" => "hello world"}
  end

  test "must handle binary data", ctx do
    bindata = <<199, 227, 1, 36, 38, 122, 216, 177, 204, 15, 63, 232, 218, 108, 216, 81, 58, 154, 130, 243, 45, 17, 198, 242, 91, 64, 226, 180, 142, 57, 183, 240>>
    file = %Operate.Cell{op: ctx.op, params: [bindata, "application/octet-stream", "binary", "test.bin"]}
    |> Operate.Cell.exec!(ctx.vm)
    assert file["data"] == bindata
  end

end
