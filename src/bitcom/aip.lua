--[[
Implements the [Author Idendity Protocol](https://github.com/BitcoinFiles/AUTHOR_IDENTITY_PROTOCOL).

**DRAFT**

@version 0.0.2
@author Libs
]]--
return function(state, algo, address, signature, ...)
  state = state or {}

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

  state['_AIP'] = aip

  return state
end