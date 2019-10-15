--[[
Implements the WeatherSV protocol. Creates an object using the given parameters,
and decodes the stringified weather data.

## Examples

    OP_FALSE OP_RETURN
      $REF
        0x01
        "{\"t\":25.22,\"h\":83,\"p\":1009,\"r\":0.25,\"c\":90,\"ws\":2.6,\"wd\":250}"
        "1HTrdRwefwnTHFGK9Yu2kM23YQb6oETMVu"
        "1561512601"
    # {
    #   channel: "1HTrdRwefwnTHFGK9Yu2kM23YQb6oETMVu",
    #   data: {
    #     c: 90,
    #     h: 83,
    #     p: 1009,
    #     r: 0.25,
    #     t: 25.22,
    #     wd: 250,
    #     ws: 2.6
    #   },
    #   timestamp: 1561512601
    # }

@version 0.1.0
@author Libs
]]--
return function(state, _cmd, data, channel, timestamp)
  state = state or {}
  assert(
    type(state) == 'table',
    'Invalid state. Must receive a table.')

  state.data = json.decode(data)
  state.channel = channel
  state.timestamp = tonumber(timestamp)

  return state
end