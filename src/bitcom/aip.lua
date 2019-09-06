--[[
Implements the [Author Idendity Protocol](https://github.com/BitcoinFiles/AUTHOR_IDENTITY_PROTOCOL).

**DRAFT**

@version 0.0.1
@author Libs
]]--
return function(ctx, algo, address, signature, ...)
  ctx = ctx or {}

  -- Define AIP object
  local aip = {
    algo = algo,
    address = address,
    signature = signature,
    indices = {...}
  }

  -- Attach veryify method
  function aip.verify(pubKey)
    -- Not implemented yet
    return nil
  end

  ctx['_AIP'] = aip

  return ctx
end