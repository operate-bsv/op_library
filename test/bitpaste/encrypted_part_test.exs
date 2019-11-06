defmodule Bitpaste.EncryptedPartTest do
  use ExUnit.Case

  setup_all do
    %{
      vm: Operate.VM.init,
      op: File.read!("src/bitpaste/encrypted_part.lua")
    }
  end


  describe "with dummy data" do
    test "must parse the data", ctx do
      res = %Operate.Cell{op: ctx.op, params: ["testsecret", "testdata"]}
      |> Operate.Cell.exec!(ctx.vm)
      assert res["encrypted"]["secret"] == "testsecret"
      assert res["encrypted"]["data"] == "testdata"
      assert is_function(res["encrypted"]["decrypt"])
    end
  end


  describe "with encrypted data from web crypto functions" do
    setup do
      pem = """
      -----BEGIN PRIVATE KEY-----
      MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCqnQkD3YssTTcluFq2AKuRZLHiIW6chJO4j0RL40nL2jzH7HiODqa85w+fqdGvHPBLxOwt/Kcd7fqnxG2xVZoS89mNXq+vsXzYYQn1kC96GQMrkzg2uyiUqhWjD74hERSN69I/X2XFlOoZ/W2FosgrR2V0shsu8N0ShoKEr0er92CmXFFCfPcRZNZk28pxMBhFsKPr+A/uVdVmwmGmNQFQm79N0ZF+tMcEIBWmiFPjWEzp3vO67j5nDygUuLJMwCg2jmHntDpNJZIUs6W8YQZStQzv3vY2ODDUCSGvkaCCsIbLTJM6uLSex7MuZ6K9UzVM8ceg9OZdn5n8yHF6cA9vAgMBAAECggEAFYCIB9Que41Zs2fKCuEHvmGt531mJtSwl1R6+4NwJABjo6CiSuj+y5TlS66HziV8BViSmXMbjrKU4froBi7vJY9U7jOuOZrJTK3iJvAeg6lOVHoP3hn1UdMjufK8eAdii0Zar4Dy3xVW8aKWYH608ntjhnMB6QcTHYgVP+qlQj9MoPf+0pbrMgfvJJpzQXbwNKWrpn09QzWQ0LABD2gpaBnll0ks0l3qWAoO0jPc4Zhaxy/Xhwm3rp0Rw+lBL4KpsTKrHliBRQnTaPahqVdl371T31YOxqyrc+Ku1xXOxRpF75YJzVCWXUQzrroy6I+lGpjNCA8Adsa/byf/xb+xlQKBgQDmhqBdyN/qhiRXLnvz6xkgdhx3w11ZYKsDHAJsqKuS7OVKAdyZx6xB9f2rKOb+lny22+PgtM5rOXY9wQ3+kHaHor6IiOuNrTP8LTaBrALNiDt1IiSgVBW33oX6wOP1d6sHU21bC6rg8pWwiwH3RP2wciHtj1d0sSr+jtNxcyXJfQKBgQC9d4m/C4dUFMFp4w7Wgsxb0+wAg2QXwQvRfmhvn5HeFf/0ubNZROtU7/7GyN0qa6TCt3CpRibOsGr0PuZZJUFsQ0bX1ehowr9oKak6Ein1T7bth5bX2h/Nkpa70nf9bfR3Fqx0KbX7iUcifMgS0EOdTU8YosMCQUEKhGYx1EIwWwKBgHYD7+9zWebHe61CN+Tcs8Vhkhth4dVS3tm9qiQUiZmzO4MSxuvXRAGUvKO2UeN+CSTYF6Y/CfnstfLRdaegL34qu95MMkMaq6VrRB9IfzrXhpDlxNhrk57JBdAklc9hzyX1+OMGaxm0NxvlXkFHiZSeKW5j1sL/vGILnoXTDEJFAoGAFgDa62fwWHBsodpvr7PS/dsXrluT9TpDIBo5ELWMYClX51jlnjllxyB0Cyvqm3GS2dYp7E6sVRah5Smk4Ld16JfLk2dRLVFonzUvZQIVA1s1mFJFz12SkfIzNS7VJoZtfKMSdg8eBk9EBppNNfof0BXZWLgWQ53Gau1DXQgUg78CgYAbIuIldcNOIYoeN/1gNyjxP1ZGpHVGV/+WR1NKSI/mWeDoUgtZCWgHt2z6w0Z+PsK41ylNmCNqvGcFtC3U0Tzec6J7Q2OZUxJ5LdXRXpoBUQ9uVSP3BCKVaFYo3ita0cJehasohFqjHZwzFKZ3M8uZa6FN+AFd/92FoXs/8QwlCg==
      -----END PRIVATE KEY-----
      """
      secret = "bYHERJ2KU1k1hmetN03HQ4f70xvhJvf1qFO0ssbk9W1fm4ZfKe3pzfNTfWZ/A/mVql8JbE3iTzK/lnCXWp44FfEC40MjHaTI5TpSGKm3mRI/C49mEiGvpESiyOiibWlG7hxPcoHBk0N0VgH8n7mw3vdzQWLxrn8pxAprBsXSnmsaLJr55HYl8ZMOjoYseyd4tOPKuvkoIkWZpcW4FGAS9XcMwM7IsjNwYeElrgS4Isqdh9hk8fSIn+OPq6CgktOu281/opEsfuQEkz4KpEoHDvJZRMa/g3fmNjG59ntYOcy/EejBdv0oGvYUxuDJnwSqA89U4A4FQLZYifJl70qfRA=="
      data = "cnsTs4A9Eq0bVmAXfQB67nwPpOVUtXwc3HTFdmIl8l4F6t2GUznaNqgFLnI="
      %{
        priv_key: BSV.Crypto.RSA.pem_decode(pem),
        secret: Base.decode64!(secret),
        data: Base.decode64!(data)
      }
    end

    test "must decrypt the data", ctx do
      res = %Operate.Cell{op: ctx.op, params: [ctx.secret, ctx.data]}
      |> Operate.Cell.exec!(ctx.vm)

      data = res["encrypted"]["decrypt"]
      |> Operate.VM.exec_function!([BSV.Crypto.RSA.PrivateKey.as_raw(ctx.priv_key)])
      assert data == "Hello world 😎"
    end
  end

end
