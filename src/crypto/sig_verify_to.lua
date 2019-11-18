--[[
Verifies the given signature using the public key. The message the signature is
verified against is assumed to be all of the data **BEFORE** the cell containing
this Op.

The signed message must be all of the tape's prior data concatentated, then
hashed using the SHA-256 algorithm, then hex encoded.

The `signature` paramater must be a Base64 encoded string.

The `pubkey` parameter can be in any of the following formats:

  * Raw 33 byte binary public key
  * Hex encoded string
  * A Bitcoin address string

## Examples

    OP_FALSE OP_RETURN
      0xF4CF3338
        "text/plain"
        "Hello world"
        |
      $REF
        "HxaO8kU3zH0zEtGJjtk71fw5RKx9mAB7ywjKCgvKkL40Mo6xTpYhyKYQshnC05BIA4Ulor1bsgIPKp2trrTr5Nw="
        "1Gvf1GupKwALrNiuw9tHoQg28rP5bPHLCg"
    # {
    #   data: "Hello world",
    #   type: "text/plain",
    #   signatures: [
    #     {
    #       cell: 2,
    #       hash: "03c1ccb5143e51a82ff46d65a034540ea1d084dbf2635828b0514a486e0a7952",
    #       pubkey: "1Gvf1GupKwALrNiuw9tHoQg28rP5bPHLCg",
    #       signature: "HxaO8kU3zH0zEtGJjtk71fw5RKx9mAB7ywjKCgvKkL40Mo6xTpYhyKYQshnC05BIA4Ulor1bsgIPKp2trrTr5Nw=",
    #       verified: true
    #     }
    #   ]
    # }

@version 0.1.0
@author Libs
]]--
return function(state, signature, pubkey)
  state = state or {}

  -- Local helper method to determine if a string is blank
  local function isblank(str)
    return str == nil or str == ''
  end

  -- Local helper method for decoding from hex string
  local function fromhex(str)
    return (string.gsub(str, '..', function(c)
      return string.char(tonumber(c, 16))
    end))
  end

  assert(
    type(state) == 'table',
    'Invalid state. Must receive a table.')
  assert(
    not isblank(signature),
    'Invalid parameters. Must receive encryped data.')
  assert(
    not isblank(pubkey),
    'Invalid parameters. Must receive encryped data.')

  -- Build the signature object
  local sig = {
    cell = ctx.cell_index or 0,
    pubkey = pubkey,
    signature = signature,
    verified = false
  }

  -- If the pubkey is hex encoded then decode to binary string
  if string.len(pubkey) == 66 and string.match(pubkey, '^[a-fA-F0-9]+$') then
    pubkey = fromhex(pubkey)
  end

  -- Get tape data, then iterate over tape data to build message for verification
  local tape = ctx.get_tape()
  if tape ~= nil then
    local message = ''
    for idx = 1, ctx.data_index do
      message = message .. tape[idx].b
    end
    sig.hash = crypto.hash.sha256(message, {encoding = 'hex'})
    sig.verified = crypto.bitcoin_message.verify(signature, sig.hash, pubkey)
  end

  -- Add signature to state. Table allows pushing multiple signatures to state
  state['signatures'] = state['signatures'] or {}
  table.insert(state['signatures'], sig)

  return state
end