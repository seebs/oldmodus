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

local ignore_prefs = false
local ignore_doubletaps = false

local origin = Screen.origin

local gear = display.newImage('gear.png')
gear:scale(60 / 533, 60 / 533)
gear.x = 32 + display.screenOriginX
gear.y = 32 + display.screenOriginY
-- gear.blendMode = 'add'
gear.isVisible = false

function Touch.ignore_prefs(flag)
  ignore_prefs = flag
end

function Touch.ignore_doubletaps(flag)
  ignore_doubletaps = flag
end

function Touch.state(func, caller)
  local now = system.getTimer()
  if state.active > 0 then
    if func then
      func(caller, state)
    end
    state.events = 0
    -- cleanup intermediate states we've already processed
    for _, e in ipairs(state.points) do
      if e.done then
	nuke_these[#nuke_these + 1] = e
      else
        if now - e.stamp > 1000 then
	  -- flag for cleanup on next pass
          e.done = true
        end
	e.events = 0
	e.previous = {}
	e.new_event = false
      end
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

Touch.is_disabled = false

function Touch.disable()
  Touch.is_disabled = true
end

function Touch.enable()
  Touch.is_disabled = false
end

function Touch.handle(event)
  local id = event.id or 'unknown'
  local e

  if Touch.is_disabled then
    return false
  end

  -- Util.printf("Touch event:")
  -- Util.dump(event, 1, '    ')

  state.events = state.events + 1

  e = active_events[id]
  if not e then
    active_events[id] = { id = id, idx = next_idx, new_event = true, events = 0, previous = {} }
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

  event.xStart = event.xStart - origin.x
  event.yStart = event.yStart - origin.y
  event.x = event.x - origin.x
  event.y = event.y - origin.y

  e.phase = event.phase
  e.events = e.events + 1
  e.stamp = event.time
  e.start_stamp = e.start_stamp or event.time
  if event.phase == 'began' then
    e.start = { x = event.xStart, y = event.yStart }
    e.current = { x = event.xStart, y = event.yStart }
    e.previous = {}
  elseif event.phase == 'moved' then
    e.previous[#e.previous + 1] = e.current
    e.current = { x = event.x, y = event.y }
  elseif event.phase == 'ended' or event.phase == 'cancelled' then
    -- if an event ended, leave it in for one last process...
    e.current = { x = event.x, y = event.y }
    e.done = true
    e.end_stamp = event.time
  end

  -- Util.printf("e:")
  -- Util.dump(e)
  -- Util.printf("state.active: %d", state.active)

  local tapped = false
  if e.done then
    if e.end_stamp and e.start_stamp and (e.end_stamp - e.start_stamp < 200) then
      if e.start and e.current and dist(e.start, e.current) < 30 then
        tapped = true
      end
    end
  end
  if tapped then
    local maybe_prefs = false
    if dist(e.current, { x = 0, y = 0 }) < 80 then
      maybe_prefs = true 
    end
    if last_tap and (e.end_stamp - last_tap.end_stamp < 450) and dist(e.current, last_tap.current) < 30 then
      if maybe_prefs and last_tap.maybe_prefs then
        storyboard.gotoScene('prefs')
      else
        Modus.next_display()
      end
      gear.isVisible = false
      last_tap = nil
    else
      local previous_maybe = last_tap and last_tap.maybe_prefs
      last_tap = e
      -- if you tap again, but it's not a double-tap, we clear the gear
      last_tap.maybe_prefs = maybe_prefs and (not previous_maybe)
      if last_tap.maybe_prefs then
        gear.isVisible = true
	gear:toFront()
      else
        gear.isVisible = false
      end
    end
  elseif e.done then
    gear.isVisible = false
  end

  return true
end

return Touch
