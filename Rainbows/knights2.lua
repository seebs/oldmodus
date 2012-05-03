local storyboard = require('storyboard')
local scene = storyboard.newScene()

scene.KNIGHTS = 6
scene.INSET = 4

scene.FADED = 0.75
scene.CYCLE = 12
-- NOT necessarily .KNIGHTS
scene.FADE_DIVISOR = 5 * scene.CYCLE

scene.square_size = math.max(32, Util.gcd(screen.height, screen.width))

function scene:createScene(event)
  while (screen.width / scene.square_size < 16) and self.square_size % 2 == 0 do
    self.square_size = self.square_size / 2
    scene.INSET = self.square_size / 8
  end
  self.squares = {}
  self.rows = math.floor(screen.height / self.square_size)
  self.columns = math.floor(screen.width / self.square_size)
  for i = 1, self.columns do
    local column = {}
    for j = 1, self.rows do
      local square = display.newRect(self.view,
      	screen.xoff + (#self.squares * self.square_size + self.INSET / 2),
	screen.yoff + (#column * self.square_size + self.INSET / 2),
	self.square_size - self.INSET,
	self.square_size - self.INSET)
      square:setFillColor(0)
      square:setStrokeColor(0)
      square.strokeWidth = self.INSET
      square:setReferencePoint(display.TopLeftReferencePoint)
      square.hue = 0
      square.cooldown = math.random(self.FADE_DIVISOR)
      column[j] = square
      self.view:insert(square)
      square.isVisible = true
    end
    self.squares[i] = column
  end
  self.knights = {}
end

function scene:colorize(square)
  local r, g, b = unpack(Rainbow.color(square.hue))
  square:setFillColor(r, g, b)
  square:setStrokeColor(r, g, b, 150)
end

function scene:bump(square, hue)
  if square then
    square.hue = Rainbow.towards(square.hue, hue)
    scene:colorize(square)
    square.cooldown = square.cooldown + (scene.FADE_DIVISOR / 2)
    if square.alpha < scene.FADED then
      square.alpha = (scene.FADED + square.alpha) / 2
    end
  end
end

function scene:setcolor(square, hue)
  if square then
    square.hue = hue
    self:colorize(square)
  end
end

function scene:find(x, y)
  while x < 1 do x = x + self.columns end
  while x > self.columns do x = x - self.columns end
  while y < 1 do y = y + self.rows end
  while y > self.rows do y = y - self.rows end
  return self.squares[x][y]
end

function scene:adjust(knight, quiet)
  local square = self.squares[knight.x][knight.y]
  if not quiet then
    Sounds.play(square.hue)
  end
  scene:setcolor(square, knight.hue)
  square.alpha = 1
  scene:bump(scene:find(knight.x + 1, knight.y    ), knight.hue)
  scene:bump(scene:find(knight.x - 1, knight.y    ), knight.hue)
  scene:bump(scene:find(knight.x    , knight.y + 1), knight.hue)
  scene:bump(scene:find(knight.x    , knight.y - 1), knight.hue)
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
  self.squares[knight.x][knight.y].alpha = scene.FADED + 0.1
  local p_chance = .5
  local s_chance = .5
  if self.toward then
    if self.toward[primary] > knight[primary] then
      p_chance = .8
    elseif self.toward[primary] < knight[primary] then
      p_chance = .2
    end
    if self.toward[secondary] > knight[secondary] then
      s_chance = .8
    elseif self.toward[secondary] < knight[secondary] then
      s_chance = .2
    end
  end

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

  if knight.x < 1 then knight.x = knight.x + self.columns end
  if knight.x > self.columns then knight.x = knight.x - self.columns end
  if knight.y < 1 then knight.y = knight.y + self.rows end
  if knight.y > self.rows then knight.y = knight.y - self.rows end
  self:adjust(knight)
  knight.counter = knight.cooldown
end

function scene:enterFrame(event)
  if self.view.alpha < 1 then
    self.view.alpha = math.min(1, self.view.alpha + .03)
  end
  for _, col in ipairs(self.squares) do
    for _, square in ipairs(col) do
      if square.alpha < 1 then
	square.cooldown = square.cooldown - 1
	if square.cooldown < 1 then
          square.alpha = math.max(0, square.alpha - .002)
	  square.cooldown = self.FADE_DIVISOR
	end
      end
    end
  end
  for i, knight in ipairs(self.knights) do
    knight.counter = knight.counter - 1
    if knight.counter == 0 then
      scene:move_knight(knight)
    end
  end
end

function scene:willEnterScene(event)
  for x = 1, self.columns do
    for y = 1, self.rows do
      self.squares[x][y].hue = (x + y) % #Rainbow.hues
      self.squares[x][y].alpha = .7
      self:colorize(self.squares[x][y])
    end
  end
  self.knights = {}
  for i = 1, self.KNIGHTS do
    local knight = {
      x = math.random(self.columns),
      y = math.random(self.rows),
      counter = 30 + (i * 12),
      index = i,
      hue = ((i - 1) % #Rainbow.hues) + 1,
      cooldown = self.KNIGHTS * 12,
    }
    table.insert(self.knights, knight)
    self:adjust(knight, true)
  end
  self.view.alpha = 0
end

function scene:touch_magic(state, ...)
  if state.ordered[1] then
    self.toward = state.ordered[1].current
    self.toward.x = math.ceil((self.toward.x / self.square_size) + 0.5)
    self.toward.y = math.ceil((self.toward.y / self.square_size) + 0.5)
  else
    self.toward = nil
  end
  return true
end

function scene:enterScene(event)
  Runtime:addEventListener('enterFrame', scene)
  self.view:addEventListener('touch', Touch.handler(self.touch_magic, self))
end

function scene:didExitScene(event)
  self.view.alpha = 0
end

function scene:exitScene(event)
  Runtime:removeEventListener('enterFrame', scene)
  self.view:removeEventListener('touch', Touch.handler(self.touch_magic, self))
end

function scene:destroyScene(event)
  self.squares = nil
end

scene:addEventListener('createScene', scene)
scene:addEventListener('enterScene', scene)
scene:addEventListener('willEnterScene', scene)
scene:addEventListener('exitScene', scene)
scene:addEventListener('didExitScene', scene)
scene:addEventListener('destroyScene', scene)

return scene
