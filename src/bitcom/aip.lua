--[[
Implements the [Author Idendity Protocol](https://github.com/BitcoinFiles/AUTHOR_IDENTITY_PROTOCOL).

An `_AIP` attribute is added to the state containing a table of AIP signatures,
allowing multiple signatures to be appended to the state. Each AIP object
contains the protocol paramaters, plus a `verified` boolean attribute.

## Examples

    OP_FALSE OP_RETURN
      "19HxigV4QyBv3tHpQVcUEQyq1pzZVdoAut"
        "Hello world!"
        "text/plain"
        "utf8"
        0
        |
      $REF
        "BITCOIN_ECDSA"
        "1EXhSbGFiEAZCE5eeBvUxT6cBVHhrpPWXz"
        "HKzuHb43Xj4XpmK1YJROD/eN/58ZR0T7LuRi2QW8eFcnQg1d7tSy3QGQI/VQr09PeTQFAXniFyIFkqQYgvAlHvQ="
    # {
    #   _AIP: [
    #     {
    #       algo: "BITCOIN_ECDSA",
    #       address: "1EXhSbGFiEAZCE5eeBvUxT6cBVHhrpPWXz",
    #       indices: [],
    #       signature: "HKzuHb43Xj4XpmK1YJROD/eN/58ZR0T7LuRi2QW8eFcnQg1d7tSy3QGQI/VQr09PeTQFAXniFyIFkqQYgvAlHvQ=",
    #       verified: true
    #     }
    #   ]
    # }

@version 0.1.0
@author Libs
]]--
return function(state, algo, address, signature, ...)
  state = state or {}
  local algo = string.upper(algo or '')
  local indices = {}
  local message = ''

  assert(
    type(state) == 'table',
    'Invalid state type.')
  assert(
    algo == 'BITCOIN_ECDSA',
    'Invalid signature algorithm. Must be BITCOIN_ECDSA.')

  -- Define AIP object
  local aip = {
    algo = algo,
    address = address,
    signature = signature,
    verified = false
  }

  -- If no indices provided, assume all fields prior to current global index
  -- Otherwise, get fields by index as specified
  if next({...}) == nil then
    local max = ctx.global_index or 0
    for idx = 0, max-1 do
      table.insert(indices, idx)
    end
    aip.indices = {}
  else
    for k, idx in ipairs({...}) do
      -- Indices can be encoded as strings or unsigned integers
      if string.match(idx, '^%d+$')
        then idx = tonumber(idx)
        else idx = string.byte(idx)
      end
      table.insert(indices, idx)
    end
    aip.indices = indices
  end

  -- Get tape data, then iterate over indeces to build message for verification
  local tape = ctx.get_tape()
  if tape ~= nil then
    for k, idx in ipairs(indices) do
      message = message .. tape[idx + 1]
    end
    aip.verified = crypto.bitcoin_message.verify(signature, message, address, {encoding = 'binary'})
  end

  -- Add signature to table, allowing multiple signature adding to same state
  state['_AIP'] = state['_AIP'] or {}
  table.insert(state['_AIP'], aip)

  return state
end