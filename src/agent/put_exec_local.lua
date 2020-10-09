--[[
Executes a local tape inline by the given output index, and places the result on
the state at the given path.

## Examples

    OP_FALSE OP_RETURN
      $REF
        "foo.bar"
        "2"

@version 0.1.2
@author Libs
]]--
return function(state, path, index)
  state = state or {}

  assert(
    type(state) == 'table',
    'Invalid state. Must receive a table.')
  assert(
    type(path) == 'string' and string.match(path, '^[%a%d%.]+%[?%]?$'),
    'Invalid path. Must receive a string.')

  -- Helper function to put the value on the tip of the path. If the path ends
  -- with `[]` then the value is placed in an integer indexed table.
  local function put_value(obj, path, value)
    if string.match(path, '%[%]$') then
      local p = string.match(path, '^[%a%d]+')
      if type(obj[p]) ~= 'table' then obj[p] = {} end
      table.insert(obj[p], value)
    else
      obj[path] = value
    end
  end

  -- Helper function to extend the given object with the path and value.
  -- Splits the path into an array of keys and iterrates over each, either
  -- extending the state object or setting the value on the tip.
  local function extend(obj, path, value)
    local keys = {}
    string.gsub(path, '[^%.]+', function(k) table.insert(keys, k) end)
    for i, k in ipairs(keys) do
      if i == #keys then
        put_value(obj, k, value)
      elseif type(obj[k]) ~= 'table' then
        obj[k] = {}
      end
      obj = obj[k]
    end
  end

  -- Convert index to integer
  if string.match(index, '^[0-9]+$') then
    index = math.floor(tonumber(index))
  else
    index = string.unpack('I1', index)
  end

  local tape = agent.local_tape(tonumber(index))
  extend(state, path, agent.run_tape(tape))
  return state
end