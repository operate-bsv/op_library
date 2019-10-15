--[[
Extends the state object by placing the given values at the given keys
(overriding values where keys already exist).

Takes a variable length number of arguments and maps them into key value pairs.
Where a key is a path seperated by `.`, the object is traversed, creating a
deeply nested object until the value is set on the tip.

## Examples

    OP_RETURN
      $REF
        "user.name"
        "Joe Bloggs"
        "user.age"
        20
        |
      $REF
        "user.email"
        "joe@example.com"
        "user.age"
        24
    # {
    #   user: {
    #     age: 24,
    #     email: "joe@example.com",
    #     name: "Joe Bloggs"
    #   }
    # }

@version 0.1.0
@author Libs
]]--
return function(state, ...)
  state = state or {}
  assert(
    type(state) == 'table',
    'Invalid state. Must receive a table.')

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
  -- Unless path is blank, the state is extended
  for n = 1, select('#', ...) do
    if math.fmod(n, 2) > 0 then
      local path = select(n, ...)
      local value = select(n+1, ...)
      if path ~= nil and string.len(path) > 0 then
        extend(state, path, value)
      end
    end
  end

  return state
end