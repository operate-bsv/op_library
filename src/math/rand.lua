--[[
Generates the specified number of random 64-bit doubles. If no number
parameter is given, one random number is returned.

## Examples

    OP_RETURN
      $REF
        "2"
    # [0.8900582807863565, 0.6963011994435739]

@version 0.0.2
@author Libs
]]--
return function(ctx, n)
  ctx = ctx or {}
  n = tonumber(n) or 1
  assert(
    type(ctx) == 'table',
    'Invalid context. Must receive a table.')

  -- Set the seed for the random generate based on the txid
  local seed = tonumber(tx.txid, 16)
  math.randomseed(seed)

  -- Iterate from 1 to n, adding unique random numbers to the context
  for i = 1, n do
    local num = math.random()
    table.insert(ctx, num)
  end

  return ctx
end
