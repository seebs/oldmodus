local storyboard = require('storyboard')
local scene = storyboard.newScene()

scene.COLOR_MULTIPLIER = 4
scene.ANTS = 6

scene.FADED = 0.75
scene.FADE_DIVISOR = 12
scene.CYCLE = 6
scene.META_CYCLE = 12

local max = math.max
local min = math.min
local frame = Util.enterFrame
local touch = Touch.state

local s

function scene:createScene(event)
  s = Screen.new(self.view)
  self.hexes = Hexes.new(s, self.ANTS, self.COLOR_MULTIPLIER)
end

function scene:enterFrame(event)
  self.cooldown = self.cooldown - 1
  if self.cooldown >= 1 then
    return
  end
  self.cooldown = self.CYCLE
  local chance = math.random(100)
  local turn = 'ahead'
  if chance > 90 then
    turn = 'hard_right'
  elseif chance > 80 then
    turn = 'hard_left'
  elseif chance > 65 then
    turn = 'right'
  elseif chance > 50 then
    turn = 'left'
  end
  local ant = table.remove(self.ants, 1)
  ant.hex.hue = ant.hex.hue - 1
  ant.hex:colorize()
  self.meta_cooldown = self.meta_cooldown - 1
  -- every three turns, move towards the next ant
  if self.meta_cooldown < 1 then
    local newdir
    newdir, ant.hex = ant.hex:towards(self.ants[1].hex)
    if newdir ~= 'here' then
      ant.dir = newdir
    end
    self.meta_cooldown = self.META_CYCLE
  else
    ant.dir = Hexes.turn[ant.dir][turn]
    ant.hex = Hexes.dir[ant.dir](ant.hex)
  end
  ant.light:move(ant.hex)
  ant.hex.hue = ant.hue
  ant.hex.alpha = 1
  ant.hex:colorize()

  -- leave a trail!
  local behind
  behind = Hexes.dir[Hexes.turn[ant.dir].hard_right](ant.hex)
  behind.alpha = min(1, behind.alpha + 0.1)
  behind.hue = self.hexes.color_towards(behind.hue, ant.hue)
  behind:colorize()

  behind = Hexes.dir[Hexes.turn[ant.dir].hard_left](ant.hex)
  behind.alpha = min(1, behind.alpha + 0.1)
  behind.hue = self.hexes.color_towards(behind.hue, ant.hue)
  behind:colorize()

  table.insert(self.ants, ant)
  self.fade_cooldown = self.fade_cooldown - 1
  if self.fade_cooldown < 1 then
    for _, column in ipairs(self.hexes) do
      for _, hex in ipairs(column) do
	hex.alpha = max(0, hex.alpha - .003)
      end
    end
    self.fade_cooldown = self.FADE_DIVISOR
  end
  local removes = {}
  for k, splash in ipairs(self.splashes) do
    splash.cooldown = splash.cooldown - 1
    if splash.cooldown < 1 then
      proc = coroutine.create(scene.process_hex)
      splash.cooldown = 2
      splash.hex:splash(1, 1, proc, splash.hue)
      removes[#removes + 1] = k
    end
  end
  while #removes > 0 do
    table.remove(self.splashes, table.remove(removes))
  end
end

function scene.process_hex(hex, inc, hue)
  local self = scene
  while hex do
    local old = hex.hue
    hex.hue = hex.hexes.color_towards(hex.hue, hue)
    hex:colorize()
    hex.alpha = min(1, hex.alpha + 0.1)
    hex, increment, hue = coroutine.yield(true)
  end
end

function scene:willEnterScene(event)
  for x, column in ipairs(self.hexes) do
    for y, hex in ipairs(column) do
      hex.hue = math.random(6 * self.COLOR_MULTIPLIER)
      hex.alpha = self.FADED
      hex:colorize()
    end
  end
  self.view.alpha = 0
end

local recent_touch = { }

function scene:touch_magic(state, ...)
  if state.events == 0 then
    return
  end
  for idx, event in ipairs(state.points) do
    if event.events ~= 0 then
      local idx = event.idx
      recent_touch[idx] = recent_touch[idx] or {}
      local touch = recent_touch[idx]
      local hit_hexes = {}
      if not touch.hue then
	local start_hex = self.hexes:from_screen(event.start)
	if start_hex then
	  touch.hue = start_hex.hue
	end
      end
      for i, e in ipairs(event.previous) do
	local new = self.hexes:from_screen(e)
	if new and new ~= touch.last_hex then
	  hit_hexes[new] = true
	end
      end
      if event.current and not event.done then
	local hex = self.hexes:from_screen(event.current)
	if hex and hex ~= touch.last_hex then
	  hit_hexes[hex] = true
	end
	touch.last_hex = hex
      end
      for hex, _ in pairs(hit_hexes) do
	table.insert(self.splashes, { cooldown = 1, hex = hex, hue = touch.hue })
      end
      if event.done then
	recent_touch[idx] = nil
      end
    end
  end
end

function scene:enterScene(event)
  self.cooldown = self.CYCLE
  self.meta_cooldown = self.META_CYCLE
  self.splashes = {}
  self.ants = {}
  for i, h in ipairs(self.hexes.highlights) do
    local ant =  {
      x = math.random(self.hexes.columns),
      y = math.random(self.hexes.rows),
      index = i,
      light = h,
      dir = Hexes.directions[math.random(#Hexes.directions)],
      hue = i * scene.COLOR_MULTIPLIER,
    }
    ant.hex = self.hexes:find(ant.x, ant.y)
    ant.hex.hue = ant.hue
    ant.hex:colorize()
    h.hue = ant.hue
    h:colorize()
    self.ants[i] = ant
  end
  self.fade_cooldown = self.FADE_DIVISOR
end

function scene:destroyScene(event)
  self.hexes:removeSelf()
  self.hexes = nil
end

return scene
