--[[
Implements the [Bitkey protocol](https://bitkey.network). Returns a state with
the Bitkey identity paymail and public key. Verifies both the Bitkey and paymail
signatures.

The Bitkey API stores both signatures base64 encoded and the pubkey hex encoded.

## Examples

    OP_FALSE OP_RETURN
      $REF
        "H+g5cgN6ILgrtoxSpt25ogVkOMuC6irp8Il7e5SGVrrkC2xZMIdCNwt8TPjbIG9ZTBDrVQujT0CeRWINpXXTRHU="
        "H+OgWIxuPUV18+FFl1sXvEQ0lZ2OsYbWf385F3ZnBPSxBo4X/2K94xuSbWwDIuD8DS4O98RywgkAzgEOxRhN6+4="
        "644@moneybutton.com"
        "02f6d2857cccf8cafe9c8fdb665bd710e3b8990c45857ccdefd75bbe24a20d4e62"
    # {
    #   paymail: "644@moneybutton.com",
    #   pubkey: <<binary pubkey>>,
    #   verified: true
    # }

@version 0.1.0
@author Libs
]]--
return function(state, bitkey_sig, paymail_sig, paymail, pubkey)
  state = state or {}

  -- Local helper method to determine if a string is blank
  local function isblank(str)
    return str == nil or str == ''
  end

  assert(
    type(state) == 'table',
    'Invalid state. Must receive a table.')
  assert(
    not (isblank(bitkey_sig) or isblank(paymail_sig)),
    'Signatures must be present.')
  assert(
    not isblank(pubkey)
    and string.len(pubkey) == 66
    and string.match(pubkey, '^0[23][a-fA-F0-9]+$'),
    'Invalid pubkey. Public key must be compressed and hex-encoded.')

  -- Bitkey protocol address
  local bitkey_addr = '13SrNDkVzY5bHBRKNu5iXTQ7K7VqTh5tJC'

  -- Local helper method for decoding hex into string
  local function fromhex(str)
    return (string.gsub(str, '..', function(c)
      return string.char(tonumber(c, 16))
    end))
  end

  state.paymail = paymail
  state.pubkey = fromhex(pubkey)

  -- Verify both the bitkey and paymail signatures
  local message = crypto.hash.sha256(paymail..pubkey, {encoding = 'hex'})
  local v1 = crypto.bitcoin_message.verify(bitkey_sig, message, bitkey_addr)
  local v2 = crypto.bitcoin_message.verify(paymail_sig, pubkey, state.pubkey)

  state.verified = v1 and v2
  return state
end
