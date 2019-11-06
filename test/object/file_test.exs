defmodule Object.FileTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: Operate.VM.init,
      op: File.read!("src/object/file.lua")
    }
  end
  
  test "must create a file object", ctx do
    file = %Operate.Cell{op: ctx.op, params: ["text/plain", "hello world"]}
    |> Operate.Cell.exec!(ctx.vm)
    assert file == %{"data" => "hello world", "type" => "text/plain"}
  end

  test "must raise when any attributes are missing", ctx do
    assert_raise RuntimeError, ~r/^Lua Error/, fn ->
      %Operate.Cell{op: ctx.op, params: ["text/plain"]}
      |> Operate.Cell.exec!(ctx.vm)
    end
  end

  test "must handle binary data", ctx do
    bindata = <<199, 227, 1, 36, 38, 122, 216, 177, 204, 15, 63, 232, 218, 108, 216, 81, 58, 154, 130, 243, 45, 17, 198, 242, 91, 64, 226, 180, 142, 57, 183, 240>>
    file = %Operate.Cell{op: ctx.op, params: ["application/octet-stream", bindata]}
    |> Operate.Cell.exec!(ctx.vm)
    assert file["data"] == bindata
  end

end
