--[[
Verifies the given signature using the paymail identity. The corresponding
public key is fetched using [Bitkey](https://bitkey.network). The message the
signature is verified against is determined by the specified slice index and
length.

The signed message must be all of the data determined by the specified slice
range, concatentated, then hashed using the SHA-256 algorithm. If using Money
Button's Crypto Operations](https://docs.moneybutton.com/docs/mb-crypto-operations.html)
API, sign the hash with the `dataEncoding` option set to `hex`.

The `signature` paramater can be in any of the following formats:

  * Raw 65 byte binary signature
  * Base64 encoded string

The `slice_idx` and `slice_len` parameters specifiy the slice range to verify
the signature against. The values can either be utf8 encoded or binary integers.

The returned `verify` function loads the paymail identity's public key and 
verifies the signature against the hash, returning a boolean.

## Examples

    OP_FALSE OP_RETURN  # 0-1
      0xF4CF3338        # 2
        "text/plain"    # 3
        "Hello world"   # 4
        |               # 5
      0x9EF5FD5C        # 6
        "foo"           # 7
        "bar"           # 8
        |               # 9
      $REF
        "H7rets1FcfVEW7zInP5fbXogoh/3TkJmrMrArn7oK7PqWGB5o0ECAKgf2Pj8eL1fUxWv2pHBnJ5DbuSgFJ8s88Y="
        "test@moneybutton.com"
        "3"
        "6"
    # {
    #   data: "Hello world",
    #   foo: "bar",
    #   type: "text/plain",
    #   signatures: [
    #     {
    #       cell: 3,
    #       hash: "afebc684bc475f468a7b7cac87dd04b5da4f613142003095fb6693850fac2801",
    #       paymail: "test@moneybutton.com",
    #       signature: "H7rets1FcfVEW7zInP5fbXogoh/3TkJmrMrArn7oK7PqWGB5o0ECAKgf2Pj8eL1fUxWv2pHBnJ5DbuSgFJ8s88Y=",
    #       verify: function()
    #     }
    #   ]
    # }

@version 0.1.1
@author Libs
]]--
return function(state, signature, paymail, slice_idx, slice_len)
  state = state or {}
  local hash = nil

  -- Local helper method to determine if a string is blank
  local function isblank(str)
    return str == nil or str == ''
  end

  assert(
    type(state) == 'table',
    'Invalid state. Must receive a table.')
  assert(
    not isblank(signature),
    'Invalid parameters. Must receive signature.')
  assert(
    not isblank(paymail),
    'Invalid parameters. Must receive paymail address.')
  assert(
    not isblank(slice_idx),
    'Invalid cell index. Must receive slice index.')
  assert(
    not isblank(slice_len),
    'Invalid cell index. Must receive slice length.')

  -- Build the signature object
  local sig = {
    cell = ctx.cell_index or 0,
    paymail = paymail,
    signature = signature
  }

  -- If the signature is base64 encoded then decode to binary string
  if string.len(signature) == 88 and string.match(signature, '^[a-zA-Z0-9+/=]+$') then
    signature = base.decode64(signature)
  end

  -- Convert slice index to integer
  if string.match(slice_idx, '^[0-9]+$') then
    slice_idx = tonumber(slice_idx)
  else
    slice_idx = table.unpack(string.unpack('I1', slice_idx))
  end

  -- Convert slice length to integer
  if string.match(slice_len, '^[0-9]+$') then
    slice_len = tonumber(slice_len)
  else
    slice_len = table.unpack(string.unpack('I1', slice_len))
  end

  -- Get tape data, then iterate over tape data to build message for verification
  local tape = ctx.get_tape()
  if tape ~= nil then
    local message = ''
    for idx = slice_idx + 1, slice_idx + slice_len do
      message = message .. tape[idx].b
    end
    hash = crypto.hash.sha256(message)
    sig.hash = base.encode16(hash)
  end

  -- Define the bitkey query
  local query = { find = {}, limit = 1 }
  local c1 = {}
  local c2 = {}
  c1['out.tape.cell'] = {}
  c1['out.tape.cell']['$elemMatch'] = {
    s = '13SrNDkVzY5bHBRKNu5iXTQ7K7VqTh5tJC',
    i = 0
  }
  c2['out.tape.cell'] = {}
  c2['out.tape.cell']['$elemMatch'] = {
    s = sig.paymail,
    i = 3
  }
  query.find['$and'] = {c1, c2}

  -- Attach verify function. Loads the Bitkey and attempts to verify the
  -- signature against the hash. Returns boolean.
  function sig.verify()
    if not hash then return false end
    local tapes = agent.load_tapes_by(query, {tape_adapter = {'Operate.Adapter.Bob'}})
    if #tapes == 0 then return false end
    local bitkey = agent.run_tape(tapes[1])
    if not bitkey.verified then return false end
    return crypto.bitcoin_message.verify(signature, hash, bitkey.pubkey, {encoding = 'binary'})
  end

  -- Add signature to state. Table allows pushing multiple signatures to state
  state['signatures'] = state['signatures'] or {}
  table.insert(state['signatures'], sig)

  return state
end