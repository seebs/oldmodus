-- basic logic for loops
local Logic = {}

local touch = Touch.state
local min = math.min
local floor = math.floor
local frame_to_ms = Util.frame_to_ms
local ms_to_frame = Util.ms_to_frame

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
    storyboard.gotoScene(Logic.skip_to_new_scene)
    Logic.skip_to_new_scene = nil
    return
  end
  local this_frame = timer()
  local this_time = this_frame - Logic.last_frame
  local frames = math.floor(this_time * ms_to_frame + 0.1)
  Logic.last_frame = this_frame
  if Logic.ignore_time then
  -- collectgarbage('collect')
  -- else
    -- Util.printf("rendering took %d frame(s).", frames)
  end
  if obj.view.alpha < 1 then
    obj.view.alpha = min(obj.view.alpha + .02, 1)
  end
  if not Logic.ignore_time and (Logic.debugging_performance or (Logic.debugging_display and obj.name == Logic.debugging_display)) then
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
	-- Util.message("%.1f-%.1f %.1fms/%.1fms %d/%d drop",
	Util.printf("%.1f-%.1f %.1fms/%.1fms %d/%d drop",
		small, big, frame_time, obj.expected_frame_time,
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
  obj.frame_cooldown = obj.frame_cooldown - frames
  if obj.frame_cooldown > 0 then
    if obj.frame_cooldown > 1 then
      collectgarbage("collect")
    end
    Logic.ignore_time = true
    return
  end
  Logic.ignore_time = false
  if obj.frame_cooldown < 0 then
    Logic.frames_missed = Logic.frames_missed - obj.frame_cooldown
    Logic.times_missed = Logic.times_missed + 1
  end
  -- actual number of frames we delayed
  event.actual_frames = obj.settings.frame_delay - obj.frame_cooldown
  obj.frame_cooldown = obj.settings.frame_delay
  if obj.touch_magic then
    touch(obj.touch_magic, obj)
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
  Modus.scenes[obj.name].settings = settings
  obj.settings = settings
  obj.screen = Screen.new(obj.view)
  obj.view.alpha = 0
  if custom then
    custom(obj, event)
  end
end

function Logic.enterScene(custom, obj, event)
  obj.expected_frame_time = obj.settings.frame_delay * frame_to_ms
  Util.message('')
  -- wipe existing touches
  touch(nil)
  -- give a few ticks to think about frame rate
  time_counter = 65
  if custom then
    custom(obj, event)
  end
  Sounds.suppress(false)
  Runtime:addEventListener('enterFrame', obj)
  Logic.last_frame = timer()
end

function Logic.willEnterScene(custom, obj, event)
  obj.frame_cooldown = 0
  obj.view.alpha = 1
  Sounds.suppress(true)
  if custom then
    custom(obj, event)
  end
  Touch.enable()
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
  Touch.ignore_prefs(false)
  Touch.ignore_doubletaps(false)
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

return Logic
