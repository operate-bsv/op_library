defmodule Bitcom.WeatherSVTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: FB.VM.init,
      script: File.read!("src/bitcom/weathersv.lua")
    }
  end
  
  test "must create a weather object", ctx do
    res = %FB.Cell{script: ctx.script, params: [0x01, "{\"t\":25.22,\"h\":83,\"p\":1009,\"r\":0.25,\"c\":90,\"ws\":2.6,\"wd\":250}", "1HTrdRwefwnTHFGK9Yu2kM23YQb6oETMVu", "1561512601"]}
    |> FB.Cell.exec!(ctx.vm)
    assert res["data"] == %{ "t" => 25.22, "h" => 83, "p" => 1009, "r" => 0.25, "c" => 90, "ws" => 2.6, "wd" => 250 }
    assert res["channel"] == "1HTrdRwefwnTHFGK9Yu2kM23YQb6oETMVu"
    assert res["timestamp"] == 1561512601
  end

  test "must extend a given context", ctx do
    res = %FB.Cell{script: ctx.script, params: [0x01, "{\"t\":25.22,\"h\":83,\"p\":1009,\"r\":0.25,\"c\":90,\"ws\":2.6,\"wd\":250}", "1HTrdRwefwnTHFGK9Yu2kM23YQb6oETMVu", "1561512601"]}
    |> FB.Cell.exec!(ctx.vm, context: %{foo: "bar"})
    assert res["channel"] == "1HTrdRwefwnTHFGK9Yu2kM23YQb6oETMVu"
    assert res["foo"] == "bar"
  end

end
