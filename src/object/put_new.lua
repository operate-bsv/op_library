--[[
Creates a new object and places the state at the given path. The object is
extended by placing the given values at the given keys unless the key already
exists. Effectively the inverse of `object/put`.

Takes a variable length number of arguments and maps them into key value pairs.
Where a key is a path seperated by `.`, the table is traversed creating a nested
table until the value is set on the tip.

## Examples

    OP_FALSE OP_RETURN
      $REF
        "account"
        "user.name"
        "Joe Bloggs"
        "user.age"
        20
    # {
    #   account: {...},
    #   user: {
    #     age: 20,
    #     name: "Joe Bloggs"
    #   }
    # }

@version 0.1.0
@author Libs
]]--
return function(state, path, ...)
  state = state or {}
  local obj = {}
  assert(
    type(state) == 'table',
    'Invalid state. Must receive a table.')
  assert(
    type(path) == 'string' and string.len(path) > 0,
    'Invalid path. Must receive a string.')

  -- Helper function to extend the given object with the path and value.
  -- Splits the path into an array of keys and iterrates over each, either
  -- extending the state object or setting the value on the tip, without
  -- overwriting any existing value.
  local function extend_new(state, path, value)
    local keys = {}
    string.gsub(path, '[^%.]+', function(k) table.insert(keys, k) end)
    for i, k in ipairs(keys) do
      if type(state) ~= 'table' then
        break
      elseif state[k] == nil then
        if i == #keys then state[k] = value else state[k] = {} end
      end
      state = state[k]
    end
  end

  -- Extend new object with state
  extend_new(obj, path, state)

  -- Iterrate over each vararg pair to get the path and value
  -- Unless path is blank, the state is extended
  for n = 1, select('#', ...) do
    if math.fmod(n, 2) > 0 then
      local path = select(n, ...)
      local value = select(n+1, ...)
      if path ~= nil and string.len(path) > 0 then
        extend_new(obj, path, value)
      end
    end
  end

  return obj
end