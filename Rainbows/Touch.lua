local Touch = {}

local callbacks = {}

Touch.active = nil

local dist = Util.dist

function Touch.handler(callback, ...)
  if callback then
    if not callbacks[callback] then
      callbacks[callback] = {
	callback = callback,
      }
    end
    callbacks[callback].args = { ... }
    callbacks[callback].state = { }
    Touch.active = callback
  else
    Touch.active = nil
  end
end

function Touch.handle(event)
  local id = event.id or 'unknown'
  local idx = nil
  local last = 0
  local active = 0
  local state = {}
  local args
  local func = nil
  local remove_me = false
  local callback = callbacks[Touch.active]
  if callback then
    state = callback.state
    args = callback.args
    func = callback.callback
  end
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
  state.this_event = idx

  if active > state.peak then
    state.peak = active
  end

  if not state.event[idx] then
    state.event[idx] = { start = { x = event.x, y = event.y }, idx = idx}
  end
  e = state.event[idx]
  if event.phase == 'began' or event.phase == 'moved' then
    e.previous = e.current
    e.current = { x = event.x, y = event.y }
  elseif event.phase == 'ended' then
    -- if an event ended, leave it in for one last process...
    remove_me = true
  elseif event.phase == 'cancelled' then
    state.event[idx] = nil
    state.known_ids[idx] = nil
    active = active - 1
  end
  state.active = active
  state.phase = event.phase

  state.ordered = {}
  for k, e in pairs(state.event) do
    table.insert(state.ordered, e)
  end
  table.sort(state.ordered, function(a, b) return a.idx < b.idx end)

  -- Util.printf("Processed '%s' for idx %d, active %d/%d, func %s.", event.phase, idx, active, state.peak, tostring(func))
  if func then
    func(args[1], state, unpack(args, 2))
  end
  if remove_me then
    state.touched = state.event[idx].current
    state.event[idx] = nil
    state.known_ids[idx] = nil
    state.active = state.active - 1
  end
  if state.active == 0 and state.peak <= 1 and system.getTimer() - state.stamp
  < 150 then
    local now = system.getTimer()
    if state.recentTap and now - state.recentTap < 350 and dist(state.touched, state.recentXY) < 20 then
      next_display()
      state.recentTap = nil
      state.recentXY = nil
      return
    else
      state.recentTap = now
      state.recentXY = { x = event.x, y = event.y }
    end
  end
  return true
end

return Touch
