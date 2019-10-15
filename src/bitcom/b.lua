--[[
Implements the B:// protocal and creates a file object using the given
parameters.

## Examples

    OP_RETURN
      $REF
        "Hello world"
        "text/plain"
        "utf8"
        "example.txt"
    # {
    #   data: "Hello world",
    #   encoding: "utf8",
    #   name: "example.txt"
    #   type: "text/plain",
    # }

@version 0.1.0
@author Libs
]]--
return function(state, data, mediatype, encoding, name)
  local file = state or {}
  assert(
    type(file) == 'table',
    'Invalid state. Must receive a table.')

  -- Local helper method to determine if a string is blank
  local function isblank(str)
    return str == nil or str == ''
  end

  assert(
    not isblank(data),
    'Invalid file parameters.')

  -- Build the file object
  file.data = data
  file.type = mediatype
  file.encoding = encoding
  file.name = name

  -- Nullify blank attributes
  if isblank(file.type) then file.type = nil end
  if isblank(file.name) then file.name = nil end
  if isblank(file.encoding) then
    -- Default text files to utf8 encoding
    if not isblank(file.type) and string.match(file.type, '^text%/') then
      file.encoding = 'utf8'
    else
      file.encoding = nil
    end
  end

  return file
end