--[[
Places the given encrypted data on the context at the specifid path, with a
`decrypt` function to handle decryption. Uses RSA/AES and is compatible with
the Web Crypto API.

The `path` parameter must be an alphanumeric path. When it is dot delimeted the
value is set on a deeply nested table. If the path ends in `[]` the value is
placed in an array - allowing multiple values to be placed at the same path.

The `secret` parameter is the symetric encryption secret which must be encrypted
using the RSA-OAEP algorithm.

The `data` parameter must be encrypted using the AES alogrithm in GCM-256 mode.
The encrypted data should be in the following order: `<<iv, data, tag>>`

The function optionally accepts a variable length number of other arguments and
maps them into key value pairs and extends the object.

The returned `decrypt` function accepts an RSA private key and returns the
unencrypted data.

## Examples

    OP_RETURN
      $REF
        "secure.data"
        "encrypted secret"
        "encrypted data"
        "type"
        "text/plain"
    # {
    #   secure: {
    #     data: {
    #       data: "encrypted data",
    #       decrypt: function(privatekey),
    #       secret: "encrypted secret",
    #       type: "text/plain"
    #     }
    #   }
    # }

    OP_RETURN
      $REF
        "secure[]"
        "secret1"
        "encrypted data"
        "|"
      $REF
        "secure[]"
        "secret2"
        "more encrypted data"
    # {
    #   secure: [
    #     {
    #       data: "encrypted data",
    #       decrypt: function(privatekey),
    #       secret: "secret1"
    #     },
    #     {
    #       data: "more encrypted data",
    #       decrypt: function(privatekey),
    #       secret: "secret2"
    #     }
    #   ]
    # }

@version 0.0.1
@author Libs
]]--
return function(ctx, path, secret, data, ...)
  ctx = ctx or {}

  -- Local helper method to determine if a string is blank
  local function isblank(str)
    return str == nil or str == ''
  end

  assert(
    type(ctx) == 'table',
    'Invalid context. Must receive a table.')
  assert(
    string.match(path, '^[%a%d%.]+%[?%]?$'),
    'Invalid path. Must be dot delimeted alphanumeric path.')
  assert(
    not isblank(secret) and not isblank(data),
    'Invalid parameters. Must receive secret and encrypted data.')
  
  -- Helper function to put the value on the tip of the path. If the path ends
  -- with `[]` then the value is placed in an integer indexed table.
  local function put_value(ctx, path, value)
    if string.match(path, '%[%]$') then
      local p = string.match(path, '^[%a%d]+')
      if type(ctx[p]) ~= 'table' then ctx[p] = {} end
      table.insert(ctx[p], value)
    else
      ctx[path] = value
    end
  end

  -- Helper function to extend the given object with the path and value.
  -- Splits the path into an array of keys and iterrates over each, either
  -- extending the context object or setting the value on the tip.
  local function extend(ctx, path, value)
    local keys = {}
    string.gsub(path, '[^%.]+', function(k) table.insert(keys, k) end)
    for i, k in ipairs(keys) do
      if i == #keys then
        put_value(ctx, k, value)
      elseif type(ctx[k]) ~= 'table' then
        ctx[k] = {}
      end
      ctx = ctx[k]
    end
  end

  -- Build the encrypted data object
  local encrypted = {
    data = data,
    secret = secret
  }

  -- Iterrate over each vararg pair to get the path and value
  -- Unless path is blank, the object is extended
  for n = 1, select('#', ...) do
    if math.fmod(n, 2) > 0 then
      local path = select(n, ...)
      local value = select(n+1, ...)
      if not isblank(path) and path ~= 'data' and path ~= 'secret' then
        extend(encrypted, path, value)
      end
    end
  end

  -- Attach decrypion method the recieves an RSA private key
  -- Private key must be in raw erlang style (array of binaries)
  function encrypted.decrypt(privatekey)
    local key = crypto.rsa.decrypt(encrypted.secret, privatekey)
    return crypto.aes.decrypt(encrypted.data, key)
  end

  extend(ctx, path, encrypted)
  return ctx
end