--[[
A noop function that simply returns the unaltered state. Useful for skipping
unimplemented protocols.

## Examples

    OP_RETURN
      $REF

@version 0.1.0
@author Libs
]]--
return function(state)
  return state
end