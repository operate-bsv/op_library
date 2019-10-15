--[[
Extends the state table at the given path, and puts a new object from the
given keys and values (overriding values where keys already exist).

Takes a variable length number of arguments and maps them into key value pairs.
Where a key is a path seperated by `.`, the table is traversed creating a nested
table until the value is set on the tip.

## Examples

    OP_RETURN
      $REF
        "user"
        "name"
        "Joe Bloggs"
        "age"
        20
    # {
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
  -- extending the state object or setting the value on the tip.
  local function extend(state, path, value)
    local keys = {}
    string.gsub(path, '[^%.]+', function(k) table.insert(keys, k) end)
    for i, k in ipairs(keys) do
      if i == #keys then
        state[k] = value
      elseif type(state[k]) ~= 'table' then
        state[k] = {}
      end
      state = state[k]
    end
  end

  -- Iterrate over each vararg pair to get the path and value
  -- Unless path is blank, the PUT object is extended
  for n = 1, select('#', ...) do
    if math.fmod(n, 2) > 0 then
      local path = select(n, ...)
      local value = select(n+1, ...)
      if path ~= nil and string.len(path) > 0 then
        extend(obj, path, value)
      end
    end
  end

  -- Extend the state
  extend(state, path, obj)
  return state
end