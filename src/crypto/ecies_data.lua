--[[
Places the given encrypted data on the context at the specifid path, with a
`decrypt` function to handle decryption. Uses ECIES and is compatible with
Electrum and bsv.js ECIES implementations.

The `path` parameter must be an alphanumeric path. When it is dot delimeted the
value is set on a deeply nested table. If the path ends in `[]` the value is
placed in an array - allowing multiple values to be placed at the same path.

The `data` parameter must be encrypted using Electrum's ECIES implementation.

The returned `decrypt` function accepts an ECDSA private key and returns the
unencrypted data.

## Examples

    OP_RETURN
      $REF
        "secure.data"
        "encrypted data"
    # {
    #   secure: {
    #     data: {
    #       data: "encrypted data",
    #       decrypt: function(privatekey)
    #     }
    #   }
    # }

    OP_RETURN
      $REF
        "secure[]"
        "encrypted data"
        "|"
      $REF
        "secure[]"
        "more encrypted data"
    # {
    #   secure: [
    #     {
    #       data: "encrypted data",
    #       decrypt: function(privatekey)
    #     },
    #     {
    #       data: "more encrypted data",
    #       decrypt: function(privatekey)
    #     }
    #   ]
    # }

@version 0.0.1
@author Libs
]]--
return function(ctx, path, data)
  ctx = ctx or {}
  assert(
    type(ctx) == 'table',
    'Invalid context. Must receive a table.')
  assert(
    string.match(path, '^[%a%d%.]+%[?%]?$'),
    'Invalid path. Must be dot delimeted alphanumeric path.')
  assert(
    not (data == nil or data == ''),
    'Invalid parameters. Must receive encryped data.')
  
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
    data = data
  }

  -- Attach decrypion method the recieves an ECSDA private key
  function encrypted.decrypt(privatekey)
    return crypto.ecies.decrypt(encrypted.data, privatekey)
  end

  extend(ctx, path, encrypted)
  return ctx
end