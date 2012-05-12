-- basic logic for loops
local Logic = {}

local touch = Touch.state

local last_times = {}

function Logic.enterFrame(custom, obj, event)
  table.insert(last_times, system.getTimer())
  if #last_times > 61 then
    local small, big
    prev = table.remove(last_times, 1)
    time_counter = time_counter - 1
    if time_counter < 1 then
      small = 9999
      big = 0
      for i, next in ipairs(last_times) do
	t = next - prev
	prev = next
	if t < small then
	  small = t
	end
	if t > big then
	  big = t
	end
      end
      local time = last_times[61] - last_times[1]
      local frame_time = time / 60
      local fps = 1000 / frame_time
      Util.message("%.1f-%.1f %.1fms %.1ffps", small, big, frame_time, fps)
      time_counter = 60
    end
  end
  if obj.touch_magic then
    touch(obj.touch_magic, self)
  end
  if self.view.alpha < 1 then
    self.view.alpha = min(self.view.alpha + .01, 1)
  end
  if custom then
    custom(obj, event)
  end
end

function Logic.wrap(object, method)
  local custom_func = object[method]
  local logic_func = Logic[method]
  if not logic_func then
    Util.printf("Fatal:  No Logic[%s] to wrap.", tostring(method))
    return
  end
  return function(...) return logic_func(custom_func, ...) end
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
  Util.dump(obj)
  local settings = Settings.scene(obj.name)
  obj.settings = settings
  if custom then
    custom(obj, event)
  end
  obj.view.alpha = 0
end

function Logic.enterScene(custom, obj, event)
  if custom then
    custom(obj, event)
  end
  Runtime:addEventListener('enterFrame', obj)
end

function Logic.willEnterScene(custom, obj, event)
  if custom then
    custom(obj, event)
  end
  obj.view.alpha = 0
end

function Logic.exitScene(custom, obj, event)
  if custom then
    custom(obj, event)
  end
  Runtime:removeEventListener('enterFrame', obj)
end

function Logic.didExitScene(custom, obj, event)
  if custom then
    custom(obj, event)
  end
  obj.view.alpha = 0
end

function Logic.destroyScene(custom, obj, event)
  if custom then
    custom(obj, event)
  end
end

Logic.handled_events = {
  'createScene',
  'overlayBegan',
  'overlayEnded',
  'willEnterScene',
  'enterScene',
  'didExitScene',
  'exitScene',
  'destroyScene',
}

function Logic:logicize(scene)
  for i, e in ipairs(Logic.handled_events) do
    -- note: Logic.wrap stashes a copy of the original function
    scene[e] = Logic.wrap(scene, e)
    scene:addEventListener(e, scene)
  end
end

return Logic
