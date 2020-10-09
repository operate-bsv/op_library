--[[
Implements the [Hash Author Idendity Protocol](https://github.com/torusJKL/BitcoinBIPs/blob/master/HAIP.md).

An `_HAIP` attribute is added to the state containing a table of HAIP signatures,
allowing multiple signatures to be appended to the state. Each HAIP object
contains the protocol paramaters, plus the `hash` and `verified` boolean
attributes.

## Examples

    OP_FALSE OP_RETURN
      "19HxigV4QyBv3tHpQVcUEQyq1pzZVdoAut"
        "{ \"message\": \"Hello world!\" }"
        "application/json"
        "UTF-8"
        "hello.json"
        |
      $REF
        "SHA256"
        "BITCOIN_ECDSA"
        "1Ghayxcf8askMqL9EV9V9QpExTR2j6afhv"
        "H6Y5LXIZRaSQ0CJEt5eY1tbUhKTxII31MZwSpEYv5fqmZLzwuylAwrtHiI3lk3yCqf3Ib/Uv3LpAfCoNSKk68fY="
        0x00
    # {
    #   _HAIP: [
    #     {
    #       sig_algo: "SHA256",
    #       sig_algo: "BITCOIN_ECDSA",
    #       address: "1Ghayxcf8askMqL9EV9V9QpExTR2j6afhv",
    #       indices: [],
    #       signature: "H6Y5LXIZRaSQ0CJEt5eY1tbUhKTxII31MZwSpEYv5fqmZLzwuylAwrtHiI3lk3yCqf3Ib/Uv3LpAfCoNSKk68fY=",
    #       hash: "733c8e0d921a72e1e650c16820cbcca53aac42ba98c3b27635c2dc978e11fc7f",
    #       verified: true
    #     }
    #   ],
    #   data: "{ \"message\": \"Hello world!\" }",
    #   encoding: "UTF-8",
    #   name: "hello.json",
    #   type: "application/json",
    # }

@version 0.1.3
@author Libs
]]--
return function(state, hash_algo, sig_algo, address, signature, idx_usize, idx_bin)
  state = state or {}
  local hash_algo = string.upper(hash_algo or '')
  local sig_algo = string.upper(sig_algo or '')
  local idx_usize = string.unpack('I1', idx_usize)
  local indices = {}
  local message = ''

  -- Local helper method to determine if a value is in a table
  local function contains(haystack, needle)
    for i, val in ipairs(haystack) do
      if needle == val then return true end
    end
    return false
  end

  assert(
    type(state) == 'table',
    'Invalid state. Must receive a table.')
  assert(
    contains({'RIPEMD160', 'SHA1', 'SHA256', 'SHA512'}, hash_algo),
    'Invalid hash algorithm. Must be RIPEMD160, SHA1, SHA256 or SHA512.')
  assert(
    sig_algo == 'BITCOIN_ECDSA',
    'Invalid signature algorithm. Must be BITCOIN_ECDSA.')
  assert(
    idx_usize >= 0 and idx_usize <= 2,
    'Invalid index unit size. Implementation only supports 1 or 2 byte index units.')

  -- Define HAIP object
  local haip = {
    hash_algo = hash_algo,
    sig_algo = sig_algo,
    address = address,
    signature = signature,
    indices = {},
    verified = false
  }
  
  -- If no indices provided, assume all fields prior to current global index
  -- Otherwise, get fields by index as specified
  if idx_usize == 0 then
    local max = ctx.data_index or 0
    for idx = 0, max-1 do
      table.insert(indices, idx)
    end
  else
    local fmt = '<I' .. idx_usize
    local i = 1
    while i <= string.len(idx_bin) do
      idx, i = string.unpack(fmt, idx_bin, i)
      table.insert(indices, idx)
    end
    haip.indices = indices
  end

  -- Local helper method for encoding an integer into a variable length binary
  local function varint(int)
    if      int < 253         then return string.pack('B', int)
    elseif  int < 0x10000     then return string.pack('B<I2', 253, int)
    elseif  int < 0x100000000 then return string.pack('B<I4', 254, int)
    else                           return string.pack('B<I8', 255, int)
    end
  end

  -- Get tape data, then iterate over indeces to build message for verification
  local tape = ctx.get_tape()
  if tape ~= nil then
    for k, idx in ipairs(indices) do
      local data = tape[idx + 1]
      if data.op == nil then
        message = message .. varint(string.len(data.b)) .. data.b
      else
        message = message .. data.b
      end
    end
    message = base.encode16(message)
    haip.hash = crypto.hash[ string.lower(hash_algo) ](message, {encoding = 'hex'})
    haip.verified = crypto.bitcoin_message.verify(signature, haip.hash, address)
  end

  -- Add signature to table, allows pushing multiple signatures to state
  state['_HAIP'] = state['_HAIP'] or {}
  table.insert(state['_HAIP'], haip)

  return state
end