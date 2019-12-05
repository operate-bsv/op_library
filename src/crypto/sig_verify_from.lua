--[[
Verifies the given signature using the public key. The message the signature is
verified against is assumed to be all of the data **AFTER** the cell containing
this Op.

The signed message must be all of the tape's following data concatentated, then
hashed using the SHA-256 algorithm.

The `signature` paramater can be in any of the following formats:

  * Raw 65 byte binary signature
  * Base64 encoded string

The `pubkey` parameter can be in any of the following formats:

  * Raw 33 byte binary public key
  * Hex encoded string
  * A Bitcoin address string

## Examples

    OP_FALSE OP_RETURN
      $REF
        "IEfsOwm4+k05NDCXLr96KB0DPGJZY66dQrTvt/4XB1yXBPF726E2RVSfWa1GcliprPXCVQeakEv6NUEBPKHBcYQ="
        "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw"
        |
      0xF4CF3338
        "text/plain"
        "Hello world"
        |
      0x9EF5FD5C
        "foo"
        "bar"
    # {
    #   data: "Hello world",
    #   foo: "bar",
    #   type: "text/plain",
    #   signatures: [
    #     {
    #       cell: 1,
    #       hash: "3fa2f0e6ed5f72c78f8cb90142ece18f4d210f282740cfeba6bc9363b76ea5df",
    #       pubkey: "17ApWGpQvvUMMq9QhisbmBifGqoCUFHGaw",
    #       signature: "IEfsOwm4+k05NDCXLr96KB0DPGJZY66dQrTvt/4XB1yXBPF726E2RVSfWa1GcliprPXCVQeakEv6NUEBPKHBcYQ=",
    #       verified: true
    #     }
    #   ]
    # }

@version 0.2.0
@author Libs
]]--
return function(state, signature, pubkey)
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

  -- If the signature is base64 encoded then decode to binary string
  if string.len(signature) == 88 and string.match(signature, '^[a-zA-Z0-9+/=]+$') then
    signature = base.decode64(signature)
  end

  -- If the pubkey is hex encoded then decode to binary string
  if string.len(pubkey) == 66 and string.match(pubkey, '^[a-fA-F0-9]+$') then
    pubkey = base.decode16(pubkey)
  end

  -- Get tape data, then iterate over tape data to build message for verification
  local tape = ctx.get_tape()
  local cell = ctx.get_cell()
  if tape ~= nil and cell ~= nil then
    local start = ctx.data_index + 1 + #cell
    local message = ''
    for idx = start, #tape do
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