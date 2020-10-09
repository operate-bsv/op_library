--[[
Verifies the given signature using the public key. The message the signature is
verified against is determined by the specified slice index and length.

The signed message must be all of the data determined by the specified slice
range, concatentated, then hashed using the SHA-256 algorithm.

The `signature` paramater can be in any of the following formats:

  * Raw 65 byte binary signature
  * Base64 encoded string

The `pubkey` parameter can be in any of the following formats:

  * Raw 33 byte binary public key
  * Hex encoded string
  * A Bitcoin address string

The `slice_idx` and `slice_len` parameters specifiy the slice range to verify
the signature against. The values can either be utf8 encoded or binary integers.

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
        "H8mBei7GqDDHwOgya4GL68TFOIo1DlK0k/7s5LHWEMQ7Wd1Kpi3PDMetE/5ToUJJqYKq3lz2HY6EhbNJxe3sO2M="
        "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw"
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
    #       pubkey: "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw",
    #       signature: "H8mBei7GqDDHwOgya4GL68TFOIo1DlK0k/7s5LHWEMQ7Wd1Kpi3PDMetE/5ToUJJqYKq3lz2HY6EhbNJxe3sO2M=",
    #       verified: true
    #     }
    #   ]
    # }

@version 0.1.2
@author Libs
]]--
return function(state, signature, pubkey, slice_idx, slice_len)
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
    not isblank(slice_idx),
    'Invalid cell index. Must receive slice index.')
  assert(
    not isblank(slice_len),
    'Invalid cell index. Must receive slice length.')

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

  -- Convert slice index to integer
  if string.match(slice_idx, '^[0-9]+$') then
    slice_idx = tonumber(slice_idx)
  else
    slice_idx = string.unpack('I1', slice_idx)
  end

  -- Convert slice length to integer
  if string.match(slice_len, '^[0-9]+$') then
    slice_len = tonumber(slice_len)
  else
    slice_len = string.unpack('I1', slice_len)
  end

  -- Get tape data, then iterate over tape data to build message for verification
  local tape = ctx.get_tape()
  if tape ~= nil then
    local message = ''
    for idx = slice_idx + 1, slice_idx + slice_len do
      message = message .. tape[idx].b
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
