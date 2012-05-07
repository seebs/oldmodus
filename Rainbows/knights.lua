local storyboard = require('storyboard')
local scene = storyboard.newScene()

scene.KNIGHTS = 6

scene.FADED = 0.75
scene.CYCLE = 12

local s

function scene:createScene(event)
  s = Screen.new(self.view)
  self.squares = Squares.new(s, self.KNIGHTS)
  self.knights = {}
end

function scene:bump(square)
  if square then
    square.hue = ((square.hue + 1) % #Rainbow.hues)
    square:colorize()
    if square.alpha < scene.FADED then
      square.alpha = (scene.FADED + square.alpha) / 2
    end
  end
end

function scene:adjust(knight, quiet)
  local square = self.squares[knight.x][knight.y]
  scene:bump(square)
  scene:bump(square)
  if knight.light then
    knight.light.hue = square.hue
    knight.light:colorize()
    if knight.light.hue == square.hue then
      knight.light.alpha = 0.6
      knight.light.blendMode = 'add'
    else
      knight.light.alpha = 0.8
      knight.light.blendMode = 'blend'
    end
    knight.light:move(square)
  end
  if not quiet then
    Sounds.play(square.hue)
  end
  square.alpha = 1
  scene:bump(square:find(1, 0))
  scene:bump(square:find(-1, 0))
  scene:bump(square:find(0, 1))
  scene:bump(square:find(0, -1))
end

function scene:move_knight(knight)
  local primary, secondary
  if math.random(2) == 2 then
    primary = 'x'
    secondary = 'y'
  else
    primary = 'y'
    secondary = 'x'
  end
  local p_chance = .5
  local s_chance = .5

  self.squares[knight.x][knight.y].alpha = scene.FADED + 0.1

  if math.random() < p_chance then
    knight[primary] = knight[primary] + 2
  else
    knight[primary] = knight[primary] - 2
  end
  if math.random() < s_chance then
    knight[secondary] = knight[secondary] + 1
  else
    knight[secondary] = knight[secondary] - 1
  end
  knight.square = self.squares:find(knight.x, knight.y)
  knight.x = knight.square.logical_x
  knight.y = knight.square.logical_y

  self:adjust(knight)
  knight.counter = knight.cooldown
end

function scene:enterFrame(event)
  Util.enterFrame()
  if self.view.alpha < 1 then
    self.view.alpha = math.min(1, self.view.alpha + .03)
  end
  local knight = self.knights[1]
  knight.counter = knight.counter - 1
  if knight.counter < 0 then
    scene:move_knight(knight)
    table.remove(self.knights, 1)
    knight.counter = self.CYCLE
    table.insert(self.knights, knight)
    if knight.index == 1 then
      for _, column in ipairs(self.squares) do
	for _, square in ipairs(column) do
	  square.alpha = math.max(0, square.alpha - .0001)
	end
      end
    end
  end
end

function scene:willEnterScene(event)
  for x, column in ipairs(self.squares) do
    for y, square in ipairs(column) do
      square.hue = 1
      square.alpha = self.FADED
      square:colorize()
    end
  end
  self.knights = {}
  for i = 1, self.KNIGHTS do
    local knight = {
      x = math.random(self.squares.columns),
      y = math.random(self.squares.rows),
      counter = self.CYCLE,
      index = i,
      cooldown = self.CYCLE,
      light = self.squares.highlights[i]
    }
    if knight.light then
      knight.light.hue = knight.index
      knight.light:colorize()
    end
    table.insert(self.knights, knight)
    self:adjust(knight, true)
  end
  self.knights[1].counter = self.knights[1].counter + 30
  self.view.alpha = 0
end

function scene:touch_magic(state, ...)
  if state.ordered[1] and state.phase ~= 'ended' then
    self.saved_delta = self.saved_delta or { x = 0, y = 0 }
    local event = state.ordered[1]
    if event.current and event.previous then
      local delta = Util.vec_add(event.current, Util.vec_scale(event.previous, -1))
      delta = Util.vec_add(delta, self.saved_delta)
      self.saved_delta = { x = 0, y = 0 }
      if delta.x > 0 then
	self.saved_delta.x = delta.x % Squares.square_size
        delta.x = math.floor(delta.x / Squares.square_size)
      elseif delta.x < 0 then
	self.saved_delta.x = (delta.x % Squares.square_size)
        delta.x = math.ceil(delta.x / Squares.square_size)
	if self.saved_delta.x > 0 then
	  self.saved_delta.x = self.saved_delta.x - Squares.square_size
	end
      end
      if delta.y > 0 then
	self.saved_delta.y = delta.y % Squares.square_size
        delta.y = math.floor(delta.y / Squares.square_size)
      elseif delta.y < 0 then
	self.saved_delta.y = (delta.y % Squares.square_size)
        delta.y = math.ceil(delta.y / Squares.square_size)
	if self.saved_delta.y > 0 then
	  self.saved_delta.y = self.saved_delta.y - Squares.square_size
	end
      end
      self.squares:shift(delta.x, delta.y)
    end
  else
    self.saved_delta = nil
  end
  return true
end

function scene:enterScene(event)
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
  self.squares:removeSelf()
  self.squares = nil
  self.knights = nil
end

scene:addEventListener('createScene', scene)
scene:addEventListener('enterScene', scene)
scene:addEventListener('willEnterScene', scene)
scene:addEventListener('exitScene', scene)
scene:addEventListener('didExitScene', scene)
scene:addEventListener('destroyScene', scene)

return scene
