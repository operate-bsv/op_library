defmodule Bitcom.AIPTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: FBAgent.VM.init,
      script: File.read!("src/bitcom/aip.lua")
    }
  end

  describe "SET without a context" do
    test "must set simple key values", ctx do
      res = %FBAgent.Cell{script: ctx.script, params: ["BITCOIN_ECDSA", "1AKHViYgBGbmxi8qiJkNvoHNeDu9m3MfPE", "##computed_sig##"]}
      |> FBAgent.Cell.exec!(ctx.vm)
      assert res["_AIP"]["algo"] == "BITCOIN_ECDSA"
      assert res["_AIP"]["address"] == "1AKHViYgBGbmxi8qiJkNvoHNeDu9m3MfPE"
      assert res["_AIP"]["signature"] =="##computed_sig##"
      assert is_function(res["_AIP"]["verify"])
    end

    test "must put variable length indices into list", ctx do
      res = %FBAgent.Cell{script: ctx.script, params: ["BITCOIN_ECDSA", "1AKHViYgBGbmxi8qiJkNvoHNeDu9m3MfPE", "##computed_sig##", "1", "2", "3", "6", "7"]}
      |> FBAgent.Cell.exec!(ctx.vm)

      assert res["_AIP"]["indices"] == ["1", "2", "3", "6", "7"]
    end
  end

end
