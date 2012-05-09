local storyboard = require('storyboard')
local scene = storyboard.newScene()

scene.KNIGHTS = 6

scene.FADED = 0.75
scene.CYCLE = 12

local s

function scene:createScene(event)
  s = Screen.new(self.view)
  self.hexes = Hexes.new(s, 0, 3)
end

function scene:enterFrame(event)
  Util.enterFrame()
  if self.view.alpha < 1 then
    self.view.alpha = math.min(1, self.view.alpha + .03)
  end
  self.cooldown = self.cooldown - 1
  if self.cooldown >= 1 then
    return
  end
  self.cooldown = self.CYCLE
  local removes = {}
  for k, splash in ipairs(self.splashes) do
    splash.cooldown = splash.cooldown - 1
    if splash.cooldown < 1 then
      proc = coroutine.create(scene.process_hex)
      splash.cooldown = 2
      splash.hex:splash(splash.current, splash.current, proc)
      splash.current = splash.current + 1
      if splash.current >= splash.max then
        removes[#removes + 1] = k
      end
    end
  end
  while #removes > 0 do
    table.remove(self.splashes, table.remove(removes))
  end
  self.meta_cooldown = self.meta_cooldown - 1
  if #self.splashes < 3 and self.meta_cooldown < 1 then
    local x = math.random(self.hexes.columns)
    local y = math.random(self.hexes.rows)
    local hex = self.hexes:find(x, y)
    table.insert(self.splashes, { cooldown = 1, hex = hex, max = math.random(3) + 2, current = 1 })
    self.meta_cooldown = 3
  end
end

function scene.process_hex(hex, increment)
  local self = scene
  while hex do
    hex.hue = hex.hue + (increment or 1)
    hex:colorize()
    hex, increment = coroutine.yield(true)
  end
end

function scene:willEnterScene(event)
  for x, column in ipairs(self.hexes) do
    for y, hex in ipairs(column) do
      hex.hue = 9
      hex:colorize()
    end
  end
  self.view.alpha = 0
end

local recent_touch = {}

function scene:touch_magic(state, ...)
  if state.ordered[1] then
    local event = state.ordered[1]
    if event.current then
      local hex = self.hexes:from_screen(event.current)
      if hex then
	local do_splash = false
        if state.phase == 'began' then
	  if recent_touch.x == hex.logical_x and recent_touch.y == hex.logical_y then
	    recent_touch.count = recent_touch.count + 1
	  else
	    recent_touch.count = 1
	  end
	  recent_touch.x = hex.logical_x
	  recent_touch.y = hex.logical_y
	  do_splash = true
	elseif state.phase == 'moved' then
	  if recent_touch.x ~= hex.logical_x or recent_touch.y ~= hex.logical_y then
	    recent_touch.x = hex.logical_x
	    recent_touch.y = hex.logical_y
	    recent_touch.count = 1
	    do_splash = true
	  end
	end
	-- if do_splash then
	  -- local proc = coroutine.create(scene.process_hex)
	  -- hex:splash(recent_touch.count, recent_touch.count, proc, 1)
	-- end
	if do_splash then
	  table.insert(self.splashes, { cooldown = 1, hex = hex, max = recent_touch.count, current = 1 })
	end
      end
    end
  end
  return true
end

function scene:enterScene(event)
  self.cooldown = self.CYCLE
  self.meta_cooldown = 3
  self.splashes = {}
  Runtime:addEventListener('enterFrame', scene)
  Touch.handler(self.touch_magic, self)
end

function scene:didExitScene(event)
  self.view.alpha = 0
end

function scene:exitScene(event)
  Runtime:removeEventListener('enterFrame', scene)
  Touch.handler()
end

function scene:destroyScene(event)
  self.hexes:removeSelf()
  self.hexes = nil
end

scene:addEventListener('createScene', scene)
scene:addEventListener('enterScene', scene)
scene:addEventListener('willEnterScene', scene)
scene:addEventListener('exitScene', scene)
scene:addEventListener('didExitScene', scene)
scene:addEventListener('destroyScene', scene)

return scene
