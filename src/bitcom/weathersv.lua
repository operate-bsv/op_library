--[[
Implements the WeatherSV protocol. Creates an object using the given parameters,
and decodes the stringified weather data.

## Examples

    OP_RETURN
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

@version 0.0.1
@author Libs
]]--
return function(ctx, _cmd, data, channel, timestamp)
  ctx = ctx or {}
  assert(
    type(ctx) == 'table',
    'Invalid context. Must receive a table.')

  ctx.data = json.decode(data)
  ctx.channel = channel
  ctx.timestamp = tonumber(timestamp)

  return ctx
end