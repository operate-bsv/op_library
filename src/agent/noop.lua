--[[
A noop function that simply returns the unaltered context. Useful for skipping
unimplemented protocols.

@version 0.0.2
@author Libs
]]--
return function(ctx)
  return ctx
end