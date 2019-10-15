--[[
Generates the specified number of unique random integers, between the given
minimum and maximum range.

## Examples

    OP_RETURN
      $REF
        "6"
        "1"
        "59"
    # [3, 35, 49, 2, 5, 22]

@version 0.1.0
@author Libs
]]--
return function(state, n, min, max)
  state = state or {}
  local nums = {}
  assert(
    type(state) == 'table',
    'Invalid state. Must receive a table.')
  assert(
    max - (min-1) >= tonumber(n),
    'Invalid arguments. Insufficent range.')

  -- Set the seed for the random generate based on the txid
  local seed = tonumber(tx.txid, 16)
  math.randomseed(seed)

  -- Local helper method to generate unique random number
  local function unique_random(nums, min, max)
    local n = math.random(min, max)
    if nums[n] then n = unique_random(nums, min, max) end
    return n
  end

  -- Iterate from 1 to n, adding unique random numbers to the state
  for i = 1, n do
    local num = unique_random(nums, min, max)
    nums[num] = num
    table.insert(state, num)
  end

  return state
end
