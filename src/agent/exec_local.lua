--[[
Executes a local tape inline by the given output index, and returns the
result. The current state is passed to the loaded tape.

## Examples

    OP_FALSE OP_RETURN
      $REF
        "2"

@version 0.1.0
@author Libs
]]--
return function(state, index)
  local tape = agent.local_tape(tonumber(index))
  return agent.run_tape(tape, {state = state})
end