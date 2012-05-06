local storyboard = require('storyboard')
local scene = storyboard.newScene()

scene.KNIGHTS = 6

scene.FADED = 0.75
scene.CYCLE = 12

scene.square_size = math.max(32, Util.gcd(screen.height, screen.width))

function scene:createScene(event)
  while (screen.width / scene.square_size < 13) and self.square_size % 2 == 0 do
    self.square_size = self.square_size / 2
  end
  self.squares = {}
  self.rows = math.floor(screen.height / self.square_size)
  self.columns = math.floor(screen.width / self.square_size)
  self.sheet = graphics.newImageSheet("square.png", { width = 128, height = 128, numFrames = 1 })
  self.igroup = display.newImageGroup(self.sheet)
  self.view:insert(self.igroup)
  self.knight_lights = {}
  for i = 1, self.KNIGHTS do
    local light = display.newImage(self.sheet, 1)
    light:scale(self.square_size / 256, self.square_size / 256)
    light.isVisible = false
    self.view:insert(light)
    light.alpha = .8
    light:setReferencePoint(display.TopLeftReferencePoint)
    table.insert(self.knight_lights, light)
  end
  for i = 1, self.columns do
    local column = {}
    for j = 1, self.rows do
      local square = display.newImage(self.sheet, 1)
      square:setReferencePoint(display.TopLeftReferencePoint)
      square.x = screen.xoff + (#self.squares * self.square_size)
      square.y = screen.yoff + (#column * self.square_size)
      square:scale(self.square_size / 128, self.square_size / 128)
      square.hue = 0
      column[j] = square
      self.igroup:insert(square)
      square.isVisible = true
    end
    self.squares[i] = column
  end
  self.knights = {}
end

function scene:colorize(square, hue)
  local r, g, b = unpack(Rainbow.color(hue or square.hue))
  square:setFillColor(r, g, b)
end

function scene:bump(square)
  if square then
    square.hue = ((square.hue + 1) % #Rainbow.hues)
    self:colorize(square)
    if square.alpha < scene.FADED then
      square.alpha = (scene.FADED + square.alpha) / 2
    end
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
  scene:bump(square)
  scene:bump(square)
  if knight.light then
    -- knight.light.hue = square.hue
    -- self:colorize(knight.light)
    if knight.light.hue == square.hue then
      knight.light.alpha = 0.6
      knight.light.blendMode = 'add'
    else
      knight.light.alpha = 0.8
      knight.light.blendMode = 'blend'
    end
    knight.light:setReferencePoint(display.TopLeftReferencePoint)
    knight.light.x = square.x + self.square_size / 4
    knight.light.y = square.y + self.square_size / 4
    knight.light.isVisible = true
  end
  if not quiet then
    Sounds.play(square.hue)
  end
  square.alpha = 1
  scene:bump(scene:find(knight.x + 1, knight.y    ))
  scene:bump(scene:find(knight.x - 1, knight.y    ))
  scene:bump(scene:find(knight.x    , knight.y + 1))
  scene:bump(scene:find(knight.x    , knight.y - 1))
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
  for x = 1, self.columns do
    for y = 1, self.rows do
      self.squares[x][y].hue = 1
      self.squares[x][y].alpha = self.FADED
      self:colorize(self.squares[x][y])
    end
  end
  self.knights = {}
  for i = 1, self.KNIGHTS do
    local knight = {
      x = math.random(self.columns),
      y = math.random(self.rows),
      counter = self.CYCLE,
      index = i,
      cooldown = self.CYCLE,
      light = self.knight_lights[i]
    }
    knight.light.hue = knight.index
    self:colorize(knight.light, knight.index)
    table.insert(self.knights, knight)
    self:adjust(knight, true)
  end
  self.knights[1].counter = self.knights[1].counter + 30
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
  self.toward = nil
  Runtime:addEventListener('enterFrame', scene)
  Touch.handler(self.touch_magic, self)
end

function scene:didExitScene(event)
  self.view.alpha = 0
end

function scene:exitScene(event)
  self.toward = nil
  Runtime:removeEventListener('enterFrame', scene)
  Touch.handler()
end

function scene:destroyScene(event)
  self.squares = nil
  self.sheet = nil
  self.igroup:removeSelf()
  self.igroup = nil
  self.knights = nil
  self.knight_lights = nil
end

scene:addEventListener('createScene', scene)
scene:addEventListener('enterScene', scene)
scene:addEventListener('willEnterScene', scene)
scene:addEventListener('exitScene', scene)
scene:addEventListener('didExitScene', scene)
scene:addEventListener('destroyScene', scene)

return scene
