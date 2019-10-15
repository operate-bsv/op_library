--[[
Loads and executes a transaction inline by the given txid, and returns the
result. The current state is passed to the loaded tape.

## Examples

    OP_RETURN
      $REF
        "c081e7158d76b6962ecbd3b51182aac249615743574464aa3b96fce4a998858d"

@version 0.1.0
@author Libs
]]--
return function(state, txid)
  -- If txid is 32 bytes then convert into utf8 encoded string
  if string.len(txid) == 32 then
    txid = string.gsub(txid, ".", function(c)
      return string.format('%02x', string.byte(c))
    end)
  end

  assert(
    string.len(txid) == 64 and string.match(txid, '^[%da-f]+$'),
    'Invalid txid.')

  return agent.exec(txid, state)
end