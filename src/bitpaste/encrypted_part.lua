--[[
Attaches encrypted data to the context object, with a `decrypt` function to
handle decryption. Designed to be compatible with standard Web Crypto APIs
available in most browsers.

The `secret` parameter is the symetric encryption secret which must be encrypted
using the RSA-OAEP algorithm.

The `data` parameter must be encrypted using the AES alogrithm in GCM-256 mode.
The encrypted data should be in the following order: `<<iv, data, tag>>`

The returned `decrypt` function accepts an RSA private key and returns the
unencrypted data.

## Examples

    OP_RETURN
      $REF
        "secret"    # 256 bit encrypted secret
        "encrypted data"
    # {
    #   encrypted: {
    #     data: "encrypted data",
    #     secret: "secret",
    #     decrypt: function(privatekey)
    #   }
    # }

@version 0.0.1
@author Libs
]]--
return function(ctx, secret, data)
  ctx = ctx or {}
  assert(
    type(ctx) == 'table',
    'Invalid context. Must receive a table.')

  -- Build the encrypted data object
  local encrypted = {
    secret = secret,
    data = data
  }

  -- Attach decrypion method the recieves a private key
  -- Private key must be in raw erlang style (array of binaries)
  function encrypted.decrypt(privatekey)
    local key   = crypto.rsa.decrypt(encrypted.secret, privatekey)
    local iv    = string.sub(encrypted.data, 1, 12)
    local data  = string.sub(encrypted.data, 13, -17)
    local tag   = string.sub(encrypted.data, -16)
    return crypto.aes.decrypt(iv..tag..data, key, {aad = ''})
  end

  ctx.encrypted = encrypted
  return ctx
end