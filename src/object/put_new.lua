--[[
Extends the state at the specifed path with the given key/value pairs unless the
key already exists. Effectively the inverse of `object/put`.

Takes a variable length number of arguments and maps them into key value pairs.
Each key must be a alphanumeric path. Dot delimeted paths are iterated over
setting the value on a deeply nested table. If a key ends in `[]` the value is
pushed in to an array.

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

@version 0.2.0
@author Libs
]]--
return function(state, path, ...)
  state = state or {}
  local obj = {}
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
  -- extending the state object or setting the value on the tip, without
  -- overwriting any existing value.
  local function extend_new(obj, path, value)
    local keys = {}
    string.gsub(path, '[^%.]+', function(k) table.insert(keys, k) end)
    for i, k in ipairs(keys) do
      if type(obj) ~= 'table' then
        break
      elseif obj[k] == nil then
        if i == #keys then put_value(obj, k, value) else obj[k] = {} end
      end
      obj = obj[k]
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
      if path ~= nil and string.match(path, '^[%a%d%.]+%[?%]?$') then
        extend_new(obj, path, value)
      end
    end
  end

  return obj
end