--[[
Creates a simple file object using the given parameters.

## Examples

    OP_RETURN
      $REF
        "text/plain"
        "Hello world"
    # {
    #   data: "Hello world",
    #   type: "text/plain"
    # }

@version 0.1.0
@author Libs
]]--
return function(state, mediatype, data)
  local file = state or {}
  assert(
    type(file) == 'table',
    'Invalid context. Must receive a table.')

  -- Local helper method to determine if a string is blank
  local function isblank(str)
    return str == nil or str == ''
  end

  assert(
    not isblank(mediatype) and not isblank(data),
    'Invalid file parameters.')

  -- Build the file object
  file.data = data
  file.type = mediatype

  return file
end