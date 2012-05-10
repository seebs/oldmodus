local Touch = {}

Touch.active = nil

Touch.events = 0

local dist = Util.dist

local active_events = { }

local state = {
  points = {},
  events = 0,
  active = 0,
  peak = 0,
}
local next_idx = 1

local nuke_these = {}

function Touch.state(func, caller)
  if state.active > 0 then
    func(caller, state)
    state.events = 0
    -- cleanup intermediate states we've already processed
    for _, e in ipairs(state.points) do
      if e.done then
	nuke_these[#nuke_these + 1] = e
      end
      e.previous = {}
    end
    -- and dispose of extras
    if #nuke_these > 0 then
      for _, e in ipairs(nuke_these) do
	if e.idx < next_idx then
	  next_idx = e.idx
	end
	active_events[e.id] = nil
	state.points[e.idx] = nil
	state.active = state.active - 1
      end
      nuke_these = {}
    end
    if state.active == 0 then
      state.peak = 0
      state.stamp = system.getTimer()
    end
  end
end

local last_tap = nil

function Touch.handle(event)
  local id = event.id or 'unknown'
  local e

  state.events = state.events + 1

  -- Util.printf("event")
  -- Util.dump(event)

  e = active_events[id]
  if not e then
    active_events[id] = { id = id, idx = next_idx }
    state.points[next_idx] = active_events[id]
    e = active_events[id]
    while state.points[next_idx] do
      next_idx = next_idx + 1
    end
    state.active = state.active + 1
  end

  if state.active > state.peak then
    state.peak = state.active
  end

  e.phase = event.phase
  if event.phase == 'began' then
    e.start_stamp = event.time
    e.start = { x = event.xStart, y = event.yStart }
    e.current = { x = event.xStart, y = event.yStart }
    e.previous = {}
  elseif event.phase == 'moved' then
    e.previous[#e.previous + 1] = e.current
    e.current = { x = event.x, y = event.y }
  elseif event.phase == 'ended' or event.phase == 'cancelled' then
    -- if an event ended, leave it in for one last process...
    e.previous[#e.previous + 1] = e.current
    e.current = { x = event.x, y = event.y }
    e.done = true
    e.end_stamp = event.time
  end

  -- Util.printf("e:")
  -- Util.dump(e)
  -- Util.printf("state.active: %d", state.active)

  if e.done and (e.end_stamp - e.start_stamp < 150) and dist(e.start, e.current) < 20 then
    if last_tap and (e.end_stamp - last_tap.end_stamp < 350) and dist(e.current, last_tap.current) < 20 then
      last_tap = nil
      next_display()
    end
    last_tap = e
  end

  return true
end

return Touch
