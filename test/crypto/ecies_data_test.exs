defmodule Crypto.ECIESDataTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: Operate.VM.init,
      op: File.read!("src/crypto/ecies_data.lua")
    }
  end
  

  describe "with dummy data" do
    test "must put the encrypted object at the path", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["foo", "encrypteddata"]}
      |> Operate.Cell.exec!(ctx.vm)
      assert res["foo"]["data"] == "encrypteddata"
      assert is_function(res["foo"]["decrypt"])
    end

    test "must extend the object with key value pairs", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["foo", "encrypteddata", "type", "text/plain", "name", "foobar"]}
      |> Operate.Cell.exec!(ctx.vm)
      assert (%{"name" => "foobar", "type" => "text/plain"} = res["foo"]) == res["foo"]
    end

    test "must put the encrypted object at the nested path", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["foo.bar.baz", "encrypteddata"]}
      |> Operate.Cell.exec!(ctx.vm)
      assert res["foo"]["bar"]["baz"]["data"] == "encrypteddata"
      assert is_function(res["foo"]["bar"]["baz"]["decrypt"])
    end

    test "must put the encrypted object in an array", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["foo.bar[]", "encrypteddata"]}
      |> Operate.Cell.exec!(ctx.vm)
      assert is_list(res["foo"]["bar"])
      assert get_in(List.first(res["foo"]["bar"]), ["data"]) == "encrypteddata"
    end
  end


  describe "with invalid data" do
    test "must raise if ctx is not null or table", ctx do
      assert_raise RuntimeError, ~r/Lua Error/, fn ->
        %Operate.Cell{op: ctx.op, params: ["foo.bar", "encrypteddata"]}
        |> Operate.Cell.exec!(ctx.vm, state: 11)
      end
    end

    test "must raise if invalid path", ctx do
      assert_raise RuntimeError, ~r/Lua Error/, fn ->
        %Operate.Cell{op: ctx.op, params: ["non dot delimited p@th", "encrypteddata"]}
        |> Operate.Cell.exec!(ctx.vm)
      end
    end
  end


  describe "with encrypted data" do
    setup do
      {pub_key, priv_key} = BSV.Crypto.ECDSA.generate_key_pair
      %{
        pub_key: pub_key,
        priv_key: priv_key
      }
    end

    test "must decrypt the data", ctx do
      encdata = BSV.Crypto.ECIES.encrypt("Hello world!", ctx.pub_key)
      res = %Operate.Cell{op: ctx.op, params: ["foo", encdata]}
      |> Operate.Cell.exec!(ctx.vm)

      data = res["foo"]["decrypt"]
      |> Operate.VM.exec_function!([ctx.priv_key])
      assert data == "Hello world!"
    end
  end


  describe "with encrypted data from Electrum" do
    setup do
      key = "ZS8a1QO2KHcEfPHpRDSXeWY17l6sOptjbchh/nL9jKk="
      data = "QklFMQPBV5A3JXgal9SIf4ojjSJk0QtCfUwPPEeaWRz4t5kd3xpI5fXf/aB4RAW9/MSQgy217XSa7BJVXXq74dyfMrJIh2wmNvo+XlxN9WLwcexYU8Ugh5K7sCEphA5pKwZVQ2c="
      %{
        data: Base.decode64!(data),
        priv_key: Base.decode64!(key)
      }
    end

    test "must decrypt the data", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["foo.bar", ctx.data]}
      |> Operate.Cell.exec!(ctx.vm)

      data = res["foo"]["bar"]["decrypt"]
      |> Operate.VM.exec_function!([ctx.priv_key])
      assert data == "Hello world 😃!"
    end
  end

end
