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

local screen_origin = Screen.origin
local screen_size = Screen.size

local corners = {
  { x = 0, y = 0 },
  { x = screen_size.x, y = 0 },
  { x = 0, y = screen_size.y },
  { x = screen_size.x, y = screen_size.y }
}

local gear = display.newImage('gear.png')
gear:scale(60 / 199, 60 / 199)
gear.x = 32 + screen_origin.x
gear.y = 32 + screen_origin.y
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
    for idx = 1, state.peak do
      local e = state.points[idx]
      -- it's possible to have a discontinuous set.
      if e then
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

function Touch.ignore(event)
  return not Touch.is_disabled
end

local occasionally = 0
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

  event.xStart = event.xStart - screen_origin.x
  event.yStart = event.yStart - screen_origin.y
  event.x = event.x - screen_origin.x
  event.y = event.y - screen_origin.y

  e.phase = event.phase
  e.events = e.events + 1
  e.stamp = event.time
  e.start_stamp = e.start_stamp or event.time
  if not e.start then
    e.start = { x = event.xStart, y = event.yStart }
  end
  if event.phase == 'began' then
    e.alive = true
    e.current = { x = event.xStart, y = event.yStart }
    e.previous = {}
  elseif event.phase == 'moved' then
    e.previous[#e.previous + 1] = e.current
    e.current = { x = event.x, y = event.y }
  elseif event.phase == 'stationary' then
    -- Util.printf("got stationary event")
    -- do nothing for now
  elseif event.phase == 'ended' or event.phase == 'cancelled' then
    -- if an event ended, leave it in for one last process...
    e.current = { x = event.x, y = event.y }
    e.done = true
    e.end_stamp = event.time
  end

  -- Util.printf("state.active: %d", state.active)
  -- if state.active > 1 then
    -- occasionally = occasionally + 1
    -- if occasionally >= 100 then
      -- Util.printf("state.active > 1 for a longish time:")
      -- Util.dump(state)
      -- occasionally = 0
    -- end
  -- else
    -- occasionally = 0
  -- end

  local tapped = false
  if e.done then
    if e.end_stamp and e.start_stamp and (e.end_stamp - e.start_stamp < 200) then
      if e.start and e.current and dist(e.start, e.current) < 30 then
	if state.active == 1 then
          tapped = true
	end
      end
    end
  end
  if tapped then
    local maybe_prefs = false
    for idx, pt in ipairs(corners) do
      if dist(e.current, pt) < 80 then
        maybe_prefs = idx
      end
    end
    if last_tap and (e.end_stamp - last_tap.end_stamp < 450) and dist(e.current, last_tap.current) < 30 then
      if maybe_prefs and (maybe_prefs == last_tap.maybe_prefs) then
        storyboard.gotoScene('prefs')
      else
        Modus.next_display()
      end
      gear.isVisible = false
      last_tap = nil
    else
      local previous_maybe = last_tap and last_tap.maybe_prefs
      last_tap = e
      last_tap.maybe_prefs = maybe_prefs
      -- if you tap again, but it's not a double-tap, we clear the gear
      if last_tap.maybe_prefs and (last_tap.maybe_prefs ~= previous_maybe) then
        gear.isVisible = true
	-- move gear to the tapped corner
	local pt = corners[last_tap.maybe_prefs] or { x = 0, y = 0 }
	if pt.x == 0 then
	  gear.x = 32 + screen_origin.x
	else
	  gear.x = screen_origin.x + screen_size.x - 32
	end
	if pt.y == 0 then
	  gear.y = 32 + screen_origin.y
	else
	  gear.y = screen_origin.y + screen_size.y - 32
	end
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

-- dummy object:
Touch.dummy = display.newGroup()
Touch.dummy:addEventListener("touch", Touch.handle)
Touch.dummy:addEventListener("tap", Touch.ignore)

return Touch
