--[[
Verifies the given signature using the paymail identity. The corresponding
public key is fetched using [Bitkey](https://bitkey.network). The message the
signature is verified against is all of the data of the specified cell.

The signed message must be all of the cell's data concatentated, then hashed
using the SHA-256 algorithm. If using Money Button's
[Crypto Operations](https://docs.moneybutton.com/docs/mb-crypto-operations.html)
API, sign the hash with the `dataEncoding` option set to `hex`.

The `signature` paramater can be in any of the following formats:

  * Raw 65 byte binary signature
  * Base64 encoded string

The `cell_idx` parameter is the index of the cell you wish to verify the
signature against. The value can either be utf8 encoded or a binary integer.

The returned `verify` function loads the paymail identity's public key and 
verifies the signature against the hash, returning a boolean.

## Examples

    OP_FALSE OP_RETURN  # cell 0
      0xF4CF3338        # cell 1
        "text/plain"
        "Hello world"
        |
      0x9EF5FD5C        # cell 2
        "foo"
        "bar"
        |
      $REF              # cell 3
        "H3uSMWv5Nzs/kGLm/WuPg3zcN2c45o2ZcDLMbWde8IB5IvJGGZLUr3dUX0v5IVvw/WrI0RIxYaqB1w7IL8wU7Z4="
        "test@moneybutton.com"
        "2"
    # {
    #   data: "Hello world",
    #   foo: "bar",
    #   type: "text/plain",
    #   signatures: [
    #     {
    #       cell: 3,
    #       hash: "b9d9129b78b2f84a1c53259ca3c57ddd7f882549380304091a568b0a26127a5d",
    #       paymail: "test@moneybutton.com",
    #       signature: "H3uSMWv5Nzs/kGLm/WuPg3zcN2c45o2ZcDLMbWde8IB5IvJGGZLUr3dUX0v5IVvw/WrI0RIxYaqB1w7IL8wU7Z4=",
    #       verify: function()
    #     }
    #   ]
    # }

@version 0.1.0
@author Libs
]]--
return function(state, signature, paymail, cell_idx)
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
    'Invalid parameters. Must receive public key.')
  assert(
    not isblank(cell_idx),
    'Invalid cell index. Must receive cell index.')

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

  -- Convert cell index to integer
  if string.match(cell_idx, '^[0-9]+$') then
    cell_idx = tonumber(cell_idx)
  else
    cell_idx = table.unpack(string.unpack('I1', cell_idx))
  end

  -- Get cell data, then iterate over cell data to build message for verification
  local cell = ctx.get_cell(cell_idx)
  if cell ~= nil then
    local message = ''
    for idx = 1, #cell do
      message = message .. cell[idx].b
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