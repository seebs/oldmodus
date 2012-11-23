-- basic logic for loops
local Logic = {}
local touch = Touch
local disp = display
local debugging_display = nil
local display_index = 1
local previous_display = 1
local debugging_performance = false
local changing_displays = false
local modus = Modus

local min = math.min
local floor = math.floor
local frame_to_ms = Util.frame_to_ms
local ms_to_frame = Util.ms_to_frame

local message = Util.message
local message_fade = Util.message_fade
local message_fade_in = Util.message_fade_in

if debugging_display or debugging_performance then
  storyboard.isDebug = true
end

local last_times = {}

function Logic.wrap(object, method)
  local custom_func = object[method]
  local logic_func = Logic[method]
  if not logic_func then
    Util.printf("Fatal:  No Logic[%s] to wrap.", tostring(method))
    return
  end
  return function(...) return logic_func(custom_func, ...) end
end

local time_counter = 65
local timer = system.getTimer
Logic.last_frame = 0
Logic.skip_to_new_scene = nil

function Logic.next_frame_go_to(scene)
  Logic.skip_to_new_scene = scene
end

Logic.frames_missed = 0
Logic.times_missed = 0

function Logic.enterFrame(custom, obj, event)
  if Logic.skip_to_new_scene then
    Logic.goto(Logic.skip_to_new_scene)
    Logic.skip_to_new_scene = nil
    return
  end
  if changing_displays then
    return
  end
  if not obj or not obj.view then
    Util.printf("got object without view: %s", tostring(obj))
    return
  end
  local this_frame = timer()
  if not obj.next_frame then
    obj.next_frame = this_frame
  end
  local this_time = this_frame - Logic.last_frame
  Logic.last_frame = this_frame
  if obj.view.alpha < 1 then
    obj.view.alpha = min(obj.view.alpha + .02, 1)
  end
  message_fade()
  if not Logic.ignore_time and (debugging_performance or (debugging_display and obj.name == debugging_display)) then
    last_times[#last_times + 1] = this_time
    if #last_times > 60 then
      local small, big
      time_counter = time_counter - 1
      local total = 0
      if time_counter < 1 then
	small = 9999
	big = 0
	for i, t in ipairs(last_times) do
	  total = total + t
	  if t < small then
	    small = t
	  end
	  if t > big then
	    big = t
	  end
	  if i > 60 then
	    break
	  end
	end
	local frame_time = total / 60
	-- message("%.1f-%.1f %.1fms/%.1fms %d/%d drop",
	Util.printf("%.1f-%.1f %.1fms/%.1fms %d/%d drop",
		small, big, frame_time, obj.ms_delay,
		Logic.frames_missed, Logic.times_missed)
	Logic.frames_missed = 0
	Logic.times_missed = 0
	time_counter = 30
	new_times = {}
	for i = 31,60 do
	  new_times[i - 30] = last_times[i]
	end
	last_times = new_times
      end
    end
  end
  obj.ms_cooldown = obj.next_frame - this_frame
  -- if we are nearly a frame out, that's probably a frame.
  if obj.ms_cooldown > (frame_to_ms * 0.8) then
    if obj.ms_cooldown > frame_to_ms then
      collectgarbage("collect")
    end
    Logic.ignore_time = true
    return true
  end
  Logic.ignore_time = false
  obj.next_frame = this_frame + obj.ms_delay

  -- if obj.ms_stamp then
    -- Util.printf("cooldown: %.1f = %.1f - %.1f ms, stamp: %.1f - %.1f = %.1f ms next %.1f.",
	-- obj.ms_cooldown, obj.ms_delay, obj.ms_delay - obj.ms_cooldown,
	-- this_frame, obj.ms_stamp, this_frame - obj.ms_stamp, obj.next_frame)
  -- end
  -- obj.ms_stamp = this_frame

  -- approximate frame count: subtract remaining cooldown from delay, this tells
  -- you how long we actually delayed. convert to frames, add 0.4, take floor;
  -- this gives about the number of frames we actually delayed.
  event.actual_frames = floor((obj.ms_delay - obj.ms_cooldown) * ms_to_frame + 0.4)
  -- Util.printf("total time %.1fms, frames ~= %d",
    -- obj.ms_delay - obj.ms_cooldown, event.actual_frames)
  obj.frame_cooldown = obj.frame_delay - event.actual_frames
  if obj.frame_cooldown < 0 then
    -- we seem to have overrun...
    Logic.frames_missed = Logic.frames_missed - obj.frame_cooldown
    Logic.times_missed = Logic.times_missed + 1
  end
  if obj.touch_magic then
    touch.state(obj.touch_magic, obj)
  end
  if custom and not obj.NEVER_DO_FRAME then
    status, error = pcall(custom, obj, event)
    if not status then
      Util.printf("error calling custom frame: %s", error)
      obj.NEVER_DO_FRAME = true
    end
  end
end

function Logic.overlayBegan(custom, obj, event)
  Runtime:removeEventListener('enterFrame', obj)
  if custom then
    custom(obj, event)
  end
end

function Logic.overlayEnded(custom, obj, event)
  Runtime:addEventListener('enterFrame', obj)
  if custom then
    custom(obj, event)
  end
end

function Logic.createScene(custom, obj, event)
  -- regenerate settings in case of changes
  local settings = Settings.scene(obj.name)
  modus.scenes[obj.name].settings = settings
  obj.settings = settings
  Rainbow.change_palette(settings.palette or 'rainbow')
  obj.screen = Screen.new(obj.view)
  obj.view.alpha = 0
  if custom then
    custom(obj, event)
  end
end

function Logic.enterScene(custom, obj, event)
  -- intended behavior
  message(obj.meta.name or "Unnamed")
  message_fade_in(50)
  obj.frame_delay = obj.settings.frame_delay
  -- more precise for actual behavior
  obj.ms_delay = obj.frame_delay * frame_to_ms
  obj.ms_cooldown = 0
  obj.next_frame = nil
  -- try to force focus to 'touch'
  disp.getCurrentStage():setFocus(touch.dummy)
  -- wipe existing touches
  touch.state(nil)
  -- give a few ticks to think about frame rate
  time_counter = 65
  if custom then
    custom(obj, event)
  end
  Sounds.suppress(false)
  Runtime:addEventListener('enterFrame', obj)
  Logic.last_frame = timer()
  changing_displays = false
end

function Logic.willEnterScene(custom, obj, event)
  obj.ms_cooldown = 0
  obj.view.alpha = 1
  Sounds.suppress(true)
  if custom then
    custom(obj, event)
  end
  touch.enable()
end

function Logic.exitScene(custom, obj, event)
  Runtime:removeEventListener('enterFrame', obj)
  if custom then
    custom(obj, event)
  end
  Sounds.suppress(true)
end

function Logic.didExitScene(custom, obj, event)
  obj.view.alpha = 0
  if custom then
    custom(obj, event)
  end
  -- so I can't forget to re-enable touches
  touch.ignore_prefs(false)
  touch.ignore_doubletaps(false)
end

function Logic.destroyScene(custom, obj, event)
  if custom then
    custom(obj, event)
  end
end

Logic.handled_events = {
  'createScene',
  'destroyScene',
  'didExitScene',
  'enterFrame',
  'enterScene',
  'exitScene',
  'overlayBegan',
  'overlayEnded',
  'willEnterScene',
}

function Logic:logicize(scene)
  for i, e in ipairs(Logic.handled_events) do
    -- note: Logic.wrap stashes a copy of the original function
    scene[e] = Logic.wrap(scene, e)
    scene:addEventListener(e, scene)
  end
end

function Logic.reload_display(event)
  if debugging_performance then
    storyboard.printMemUsage()
  end
  if not event or event.phase == 'ended' or event.phase == 'release' then
    if not modus.scenes[modus.displays[display_index]].settings.enabled then
      Logic.next_display(event)
    else
      Logic.goto(modus.displays[display_index])
    end
  end
end

function Logic.last_display(event)
  if debugging_performance then
    storyboard.printMemUsage()
  end
  if not event or event.phase == 'ended' or event.phase == 'release' then
    local prev = ((display_index - 2) % #modus.displays) + 1
    Logic.goto(modus.displays[prev])
    display_index = prev
  end
end

function Logic.goto(d)
  if not changing_displays then
    changing_displays = true
    storyboard.gotoScene(d, 'fade', 100)
  end
end

function Logic.next_display(event)
  if debugging_display then
    table.insert(modus.displays, display_index + 1, debugging_display)
    debugging_display = nil
  end
  if debugging_performance then
    storyboard.printMemUsage()
  end
  local next_place = nil
  if not event or event.phase == 'ended' or event.phase == 'release' then
    local started_at = display_index
    while not next_place do
      display_index = (display_index % #modus.displays) + 1
      if display_index == started_at then
	next_place = 'prefs'
	message("You do not appear to have any other scenes enabled.  Enable some scenes.")
	break
      end
      next_place = modus.displays[display_index]
      local enabled = modus.scenes[modus.displays[display_index]].settings.enabled
      if not enabled then
	next_place = nil
      end
    end
    Logic.goto(next_place)
  end
end

return Logic
