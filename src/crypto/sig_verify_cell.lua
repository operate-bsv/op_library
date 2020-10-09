--[[
Verifies the given signature using the public key. The message the signature is
verified against is all of the data of the specified cell.

The signed message must be all of the cell's data concatentated, then hashed
using the SHA-256 algorithm.

The `signature` paramater can be in any of the following formats:

  * Raw 65 byte binary signature
  * Base64 encoded string

The `pubkey` parameter can be in any of the following formats:

  * Raw 33 byte binary public key
  * Hex encoded string
  * A Bitcoin address string

The `cell_idx` parameter is the index of the cell you wish to verify the
signature against. The value can either be utf8 encoded or a binary integer.

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
        "H8mBei7GqDDHwOgya4GL68TFOIo1DlK0k/7s5LHWEMQ7Wd1Kpi3PDMetE/5ToUJJqYKq3lz2HY6EhbNJxe3sO2M="
        "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw"
        "2"
    # {
    #   data: "Hello world",
    #   foo: "bar",
    #   type: "text/plain",
    #   signatures: [
    #     {
    #       cell: 3,
    #       hash: "b9d9129b78b2f84a1c53259ca3c57ddd7f882549380304091a568b0a26127a5d",
    #       pubkey: "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw",
    #       signature: "H8mBei7GqDDHwOgya4GL68TFOIo1DlK0k/7s5LHWEMQ7Wd1Kpi3PDMetE/5ToUJJqYKq3lz2HY6EhbNJxe3sO2M=",
    #       verified: true
    #     }
    #   ]
    # }

@version 0.1.1
@author Libs
]]--
return function(state, signature, pubkey, cell_idx)
  state = state or {}

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
    not isblank(pubkey),
    'Invalid parameters. Must receive public key.')
  assert(
    not isblank(cell_idx),
    'Invalid cell index. Must receive cell index.')

  -- Build the signature object
  local sig = {
    cell = ctx.cell_index or 0,
    pubkey = pubkey,
    signature = signature,
    verified = false
  }

  -- If the signature is base64 encoded then decode to binary string
  if string.len(signature) == 88 and string.match(signature, '^[a-zA-Z0-9+/=]+$') then
    signature = base.decode64(signature)
  end

  -- If the pubkey is hex encoded then decode to binary string
  if string.len(pubkey) == 66 and string.match(pubkey, '^[a-fA-F0-9]+$') then
    pubkey = base.decode16(pubkey)
  end

  -- Convert cell index to integer
  if string.match(cell_idx, '^[0-9]+$') then
    cell_idx = math.floor(tonumber(cell_idx))
  else
    cell_idx = math.floor(string.unpack('I1', cell_idx))
  end

  -- Get cell data, then iterate over cell data to build message for verification
  local cell = ctx.get_cell(cell_idx)
  if cell ~= nil then
    local message = ''
    for idx = 1, #cell do
      message = message .. cell[idx].b
    end
    local hash = crypto.hash.sha256(message)
    sig.hash = base.encode16(hash)
    sig.verified = crypto.bitcoin_message.verify(signature, hash, pubkey, {encoding = 'binary'})
  end

  -- Add signature to state. Table allows pushing multiple signatures to state
  state['signatures'] = state['signatures'] or {}
  table.insert(state['signatures'], sig)

  return state
end