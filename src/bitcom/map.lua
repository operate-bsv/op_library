--[[
Implements the Magic Attribute Protocol. Depending on the given mode, the
state is either extended with the given values at the given keys (overriding
values where keys already exist), or the given keys are deleted from the state.

In addition a `_MAP` attribute is attached to the state listing the mapping
changes.

## Examples

    OP_FALSE OP_RETURN
      $REF
        "SET"
        "user.name"
        "Joe Bloggs"
        "user.age"
        20
    # {
    #   user: {
    #     age: 20,
    #     name: "Joe Bloggs"
    #   },
    #   _MAP: {
    #     PUT: {
    #       "user.age": 20,
    #       "user.name": "Joe Bloggs"
    #     }
    #   }
    # }

@version 0.1.1
@author Libs
]]--
return function(state, mode, ...)
  state = state or {}
  state['_MAP'] = state['_MAP'] or {}
  local obj = {}
  local mode = string.upper(mode or '')
  assert(
    type(state) == 'table',
    'Invalid state type.')
  assert(
    mode == 'SET' or mode == 'ADD' or mode == 'DELETE',
    'Invalid MAP mode. Must be SET, ADD or DELETE.')

  -- Helper function for setting a value on a target
  local function set(target, value)
    return value
  end

  -- Helper function for concatenating two tables
  local function concat(target, value)
    target = target or {}
    for n = 1, #value do
      target[#target+n] = value[n]
    end
    return target
  end

  -- Helper function to extend the given object with the path and value.
  -- Splits the path into an array of keys and iterrates over each, either
  -- extending the state object or setting the value on the tip.
  local function extend(obj, path, value, callback)
    local keys = {}
    string.gsub(path, '[^%.]+', function(k) table.insert(keys, k) end)
    for i, k in ipairs(keys) do
      if i == #keys then
        obj[k] = callback(obj[k], value)
      elseif type(obj[k]) ~= 'table' then
        obj[k] = {}
      end
      obj = obj[k]
    end
  end

  -- Helper function to drop the path from the given object.
  -- Splits the path into an array of keys and traverses the state object
  -- until it nullifies the tip.
  local function drop(state, path)
    local keys = {}
    string.gsub(path, '[^%.]+', function(k) table.insert(keys, k) end)
    for i, k in ipairs(keys) do
      if type(state) ~= 'table' then
        break
      elseif state[k] ~= nil then
        if i == #keys then state[k] = nil end
      end
      state = state[k]
    end
  end

  -- Iterrate over each vararg pair to get the path and value.
  -- Unless path is blank, the state is extended.
  if mode == 'SET' then
    for n = 1, select('#', ...) do
      if math.fmod(n, 2) > 0 then
        local path = select(n, ...)
        local value = select(n+1, ...)
        
        if path ~= nil and string.len(path) > 0 then
          obj[path] = value
          extend(state, path, value, set)
        end
      end
    end

    -- Attach mapping to state
    extend(state['_MAP'], mode, obj, set)

  -- Takes the first vararg as the path and all subsequent args as an array of
  -- values. Unless path is blank, the state is extended.
  elseif mode == 'ADD' then
    local path = select(1, ...)
    local values = {}

    if path ~= nil and string.len(path) > 0 then
      for n = 2, select('#', ...) do
        local val = select(n, ...)
        table.insert(values, val)
      end
      obj[path] = values
      extend(state, path, values, concat)
    end

    -- Attach mapping to state
    for key, value in pairs(obj) do
      state['_MAP'][mode] = state['_MAP'][mode] or {}
      state['_MAP'][mode][key] = concat(state['_MAP'][mode][key], value)
    end

  -- Iterrate over each vararg and drop from the state
  elseif mode == 'DELETE' then
    for i, path in ipairs({...}) do
      table.insert(obj, path)
      drop(state, path)
    end
    -- Attach mapping to state
    state['_MAP'][mode] = concat(state['_MAP'][mode], obj)
  end

  return state
end