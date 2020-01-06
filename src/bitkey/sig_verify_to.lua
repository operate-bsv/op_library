--[[
Verifies the given signature using the paymail identity. The corresponding
public key is fetched using [Bitkey](https://bitkey.network). The message the
signature is verified against is assumed to be all of the data **BEFORE** the
cell containing this Op.

The signed message must be all of the tape's prior data concatentated, then
hashed using the SHA-256 algorithm. If using Money Button's
[Crypto Operations](https://docs.moneybutton.com/docs/mb-crypto-operations.html)
API, sign the hash with the `dataEncoding` option set to `hex`.

The `signature` paramater can be in any of the following formats:

  * Raw 65 byte binary signature
  * Base64 encoded string

The returned `verify` function loads the paymail identity's public key and 
verifies the signature against the hash, returning a boolean.

## Examples

    OP_FALSE OP_RETURN
      0xF4CF3338
        "text/plain"
        "Hello world"
        |
      $REF
        "H8+GubpvseT6lfuYqgJ2VEwU4Y2zTIxQMhWq5PdiVwyoZP5wMmFS7Zr3eRHzvMSOpm8bqh0AY8P+cxaaEvVndtc="
        "test@moneybutton.com"
    # {
    #   data: "Hello world",
    #   type: "text/plain",
    #   signatures: [
    #     {
    #       cell: 2,
    #       hash: "03c1ccb5143e51a82ff46d65a034540ea1d084dbf2635828b0514a486e0a7952",
    #       paymail: "test@moneybutton.com",
    #       signature: "H8+GubpvseT6lfuYqgJ2VEwU4Y2zTIxQMhWq5PdiVwyoZP5wMmFS7Zr3eRHzvMSOpm8bqh0AY8P+cxaaEvVndtc=",
    #       verify: function()
    #     }
    #   ]
    # }

@version 0.1.1
@author Libs
]]--
return function(state, signature, paymail)
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

  -- Get tape data, then iterate over tape data to build message for verification
  local tape = ctx.get_tape()
  if tape ~= nil then
    local message = ''
    for idx = 1, ctx.data_index do
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