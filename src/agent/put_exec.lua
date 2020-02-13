--[[
Loads and executes a transaction by the given txid and places the result on the
state at the given path.

## Examples

    OP_FALSE OP_RETURN
      $REF
        "foo.bar"
        "c081e7158d76b6962ecbd3b51182aac249615743574464aa3b96fce4a998858d"

@version 0.1.0
@author Libs
]]--
return function(state, path, txid)
  state = state or {}
  -- If txid is 32 bytes then convert to hex encoded string
  if string.len(txid) == 32 then
    txid = base.encode16(txid)
  end

  assert(
    type(state) == 'table',
    'Invalid state. Must receive a table.')
  assert(
    type(path) == 'string' and string.match(path, '^[%a%d%.]+%[?%]?$'),
    'Invalid path. Must receive a string.')
  assert(
    string.len(txid) >= 64 and string.match(txid, '^[%da-f]+'),
    'Invalid txid.')

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

  local tape = agent.load_tape(txid)
  extend(state, path, agent.run_tape(tape))
  return state
end