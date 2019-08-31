--[[
Extends the context table by placing the given values at the given keys
(overriding values where keys already exist).

Takes a variable length number of arguments and maps them into key value pairs.
Where a key is a path seperated by `.`, the table is traversed creating a nested
table until the value is set on the tip.

## Examples

    OP_RETURN
      $REF
        "user.name"
        "Joe Bloggs"
        "user.age"
        20
    # {
    #   user: {
    #     age: 20,
    #     name: "Joe Bloggs"
    #   }
    # }

@version 0.0.2
@author Libs
]]--
return function(ctx, ...)
  ctx = ctx or {}
  assert(
    type(ctx) == 'table',
    'Invalid context. Must receive a table.')

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

  -- Iterrate over each vararg pair to get the path and value
  -- Unless path is blank, the context is extended
  for n = 1, select('#', ...) do
    if math.fmod(n, 2) > 0 then
      local path = select(n, ...)
      local value = select(n+1, ...)
      if path ~= nil and string.len(path) > 0 then
        extend(ctx, path, value)
      end
    end
  end

  return ctx
end