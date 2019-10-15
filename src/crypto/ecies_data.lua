--[[
Places the given encrypted data on the state at the specifid path, with a
`decrypt` function to handle decryption. Uses ECIES and is compatible with
Electrum and bsv.js ECIES implementations.

The `path` parameter must be an alphanumeric path. When it is dot delimeted the
value is set on a deeply nested table. If the path ends in `[]` the value is
placed in an array - allowing multiple values to be placed at the same path.

The `data` parameter must be encrypted using Electrum's ECIES implementation.

The function optionally accepts a variable length number of other arguments and
maps them into key value pairs and extends the object.

The returned `decrypt` function accepts an ECDSA private key and returns the
unencrypted data.

## Examples

    OP_FALSE OP_RETURN
      $REF
        "secure.data"
        "encrypted data"
        "type"
        "text/plain"
    # {
    #   secure: {
    #     data: {
    #       data: "encrypted data",
    #       decrypt: function(privatekey),
    #       type: "text/plain"
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

@version 0.1.0
@author Libs
]]--
return function(state, path, data, ...)
  state = state or {}

  -- Local helper method to determine if a string is blank
  local function isblank(str)
    return str == nil or str == ''
  end

  assert(
    type(state) == 'table',
    'Invalid state. Must receive a table.')
  assert(
    string.match(path, '^[%a%d%.]+%[?%]?$'),
    'Invalid path. Must be dot delimeted alphanumeric path.')
  assert(
    not isblank(data),
    'Invalid parameters. Must receive encryped data.')
  
  -- Helper function to put the value on the tip of the path. If the path ends
  -- with `[]` then the value is placed in an integer indexed table.
  local function put_value(state, path, value)
    if string.match(path, '%[%]$') then
      local p = string.match(path, '^[%a%d]+')
      if type(state[p]) ~= 'table' then state[p] = {} end
      table.insert(state[p], value)
    else
      state[path] = value
    end
  end

  -- Helper function to extend the given object with the path and value.
  -- Splits the path into an array of keys and iterrates over each, either
  -- extending the state object or setting the value on the tip.
  local function extend(state, path, value)
    local keys = {}
    string.gsub(path, '[^%.]+', function(k) table.insert(keys, k) end)
    for i, k in ipairs(keys) do
      if i == #keys then
        put_value(state, k, value)
      elseif type(state[k]) ~= 'table' then
        state[k] = {}
      end
      state = state[k]
    end
  end

  -- Build the encrypted data object
  local encrypted = {
    data = data
  }

  -- Iterrate over each vararg pair to get the path and value
  -- Unless path is blank, the object is extended
  for n = 1, select('#', ...) do
    if math.fmod(n, 2) > 0 then
      local path = select(n, ...)
      local value = select(n+1, ...)
      if not isblank(path) and path ~= 'data' then
        extend(encrypted, path, value)
      end
    end
  end

  -- Attach decrypion method the recieves an ECSDA private key
  function encrypted.decrypt(privatekey)
    return crypto.ecies.decrypt(encrypted.data, privatekey)
  end

  extend(state, path, encrypted)
  return state
end