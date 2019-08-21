--[[
Implements the B:// protocal and creates a file object using the given
parameters. This function always creates a new context. 

## Examples

    TODO

@version 0.0.1
@author Libs
]]--
function main(_ctx, data, mediatype, encoding, name)
  -- Local helper method to determine if a string is blank
  local function isblank(str)
    return str == nil or str == ''
  end

  assert(
    not isblank(data),
    'Invalid file parameters.')

  -- Build the file object
  file = {
    data = data,
    type = mediatype,
    encoding = encoding,
    name = name
  }

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