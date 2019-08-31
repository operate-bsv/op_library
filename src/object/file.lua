--[[
Creates a simple file object using the given parameters. Any previous context is
ignored and a new context created.

## Examples

    OP_RETURN
      $REF
        "text/plain"
        "Hello world"
    # {
    #   data: "Hello world",
    #   type: "text/plain"
    # }

@version 0.0.2
@author Libs
]]--
return function(_ctx, mediatype, data)
  -- Local helper method to determine if a string is blank
  local function isblank(str)
    return str == nil or str == ''
  end

  assert(
    not isblank(mediatype) and not isblank(data),
    'Invalid file parameters.')

  -- Build the file object
  file = {
    data = data,
    type = mediatype
  }

  return file
end