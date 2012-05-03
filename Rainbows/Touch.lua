local Touch = {}

local callbacks = {}

function Touch.handler(callback, ...)
  if callback then
    if not callbacks[callback] then
      callbacks[callback] = {
	callback = callback,
      }
      local func = function(event) Touch.handle(event, callbacks[callback]) end
      callbacks[callback].func = func
    end
    callbacks[callback].args = { ... }
    callbacks[callback].state = { }
    return callbacks[callback].func
  else
    return next_display
  end
end

function Touch.handle(event, callback)
  local id = event.id or 'unknown'
  local idx = nil
  local last = 0
  local active = 0
  local state = callback.state
  local args = callback.args
  local callback = callback.callback
  state.event = state.event or {}
  state.known_ids = state.known_ids or {}
  state.peak = state.peak or 0
  state.active = state.active or 0

  if state.active == 0 then
    state.peak = 0
    state.stamp = system.getTimer()
  end

  for i, v in pairs(state.known_ids) do
    if i > last then
      last = i
    end
    if v == id then
      idx = i
    end
    active = active + 1
  end
  if not idx then
    active = active + 1
    if not last then
      state.known_ids[1] = id
      idx = 1
      last = 1
    else
      last = last + 1
      state.known_ids[last] = id
      idx = last
    end
  end

  if active > state.peak then
    state.peak = active
  end

  if not state.event[idx] then
    state.event[idx] = { start = { x = event.x, y = event.y }, count = 0, idx = idx}
  end
  e = state.event[idx]
  if event.phase == 'began' then
    e.current = { x = event.x, y = event.y }
  elseif event.phase == 'moved' then
    e.current = { x = event.x, y = event.y }
    e.count = e.count + 1
  elseif event.phase == 'ended' then
    state.event[idx] = nil
    state.known_ids[idx] = nil
    active = active - 1
  elseif event.phase == 'cancelled' then
    state.event[idx] = nil
    state.known_ids[idx] = nil
    active = active - 1
  end
  state.active = active

  state.ordered = {}
  for k, e in pairs(state.event) do
    table.insert(state.ordered, e)
  end
  table.sort(state.ordered, function(a, b) return a.idx < b.idx end)

  -- Util.printf("Processed '%s' for idx %d, active %d/%d.", event.phase, idx, active, state.peak)
  if state.active == 0 and state.peak <= 1 and system.getTimer() - state.stamp
  < 150 then
    next_display()
  elseif not callback(args[1], state, unpack(args, 2)) then
    next_display()
  end
  return true
end

return Touch
