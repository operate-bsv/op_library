--[[
Implements the Magic Attribute Protocol. Depending on the given mode, the
context is either extended with the given values at the given keys (overriding
values where keys already exist), or the given keys are deleted from the context.

In addition a `_MAP` attribute is attached to the context listing the mapping
changes.

## Examples

    OP_RETURN
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

@version 0.0.2
@author Libs
]]--
return function(ctx, mode, ...)
  ctx = ctx or {}
  local obj = {}
  local mode = string.upper(mode or '')
  assert(
    type(ctx) == 'table',
    'Invalid context type.')
  assert(
    mode == 'SET' or mode == 'DELETE',
    'Invalid MAP mode. Must be SET or DELETE.')

  -- Helper function to extend the given object with the path and value.
  -- Splits the path into an array of keys and iterrates over each, either
  -- extending the context object or setting the value on the tip.
  local function extend(ctx, path, value)
    local keys = {}
    string.gsub(path, '[^%.]+', function(k) table.insert(keys, k) end)
    for i, k in ipairs(keys) do
      if i == #keys then
        ctx[k] = value
      elseif type(ctx[k]) ~= 'table' then
        ctx[k] = {}
      end
      ctx = ctx[k]
    end
  end

  -- Helper function to drop the path from the given object.
  -- Splits the path into an array of keys and traverses the context object
  -- until it nullifies the tip.
  local function drop(ctx, path)
    local keys = {}
    string.gsub(path, '[^%.]+', function(k) table.insert(keys, k) end)
    for i, k in ipairs(keys) do
      if type(ctx) ~= 'table' then
        break
      elseif ctx[k] ~= nil then
        if i == #keys then ctx[k] = nil end
      end
      ctx = ctx[k]
    end
  end

  if mode == 'SET' then
    -- Iterrate over each vararg pair to get the path and value
    -- Unless path is blank, the context is extended
    for n = 1, select('#', ...) do
      if math.fmod(n, 2) > 0 then
        local path = select(n, ...)
        local value = select(n+1, ...)
        
        if path ~= nil and string.len(path) > 0 then
          obj[path] = value
          extend(ctx, path, value)
        end
      end
    end
  elseif mode == 'DELETE' then
    -- Iterrate over each vararg and drop from the context
    for i, path in ipairs({...}) do
      table.insert(obj, path)
      drop(ctx, path)
    end
  end
  
  -- Attach mapping to context
  ctx['_MAP'] = {}
  ctx['_MAP'][string.upper(mode)] = obj

  return ctx
end