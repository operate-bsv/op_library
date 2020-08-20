--[[
Executes a local tape inline by the given output index, and returns the
result. The current state is passed to the loaded tape.

## Examples

    OP_FALSE OP_RETURN
      $REF
        "2"

@version 0.1.1
@author Libs
]]--
return function(state, index)
  -- Convert index to integer
  if string.match(index, '^[0-9]+$') then
    index = math.floor(tonumber(index))
  else
    index = table.unpack(string.unpack('I1', index))
  end

  local tape = agent.local_tape(index)
  return agent.run_tape(tape, {state = state})
end