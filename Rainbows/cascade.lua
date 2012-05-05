local storyboard = require('storyboard')
local scene = storyboard.newScene()

scene.FADED = 0.75
scene.CYCLE = 12
scene.COLOR_MULTIPLIER = 12

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
  self.cooldown = self.CYCLE
  self.total_colors = #Rainbow.hues * self.COLOR_MULTIPLIER
  for i = 1, self.columns do
    local column = {}
    for j = 1, self.rows do
      local square = display.newImage(self.sheet, 1)
      square:setReferencePoint(display.TopLeftReferencePoint)
      square.x = screen.xoff + (#self.squares * self.square_size)
      square.y = screen.yoff + (#column * self.square_size)
      square:scale(self.square_size / 128, self.square_size / 128)
      column[j] = square
      self.igroup:insert(square)
      square.isVisible = true
    end
    self.squares[i] = column
  end
end

function scene:colorize(square, r, g, b)
  r, g, b = unpack(Rainbow.smooth(r or square.hue, self.COLOR_MULTIPLIER))
  square:setFillColor(r, g, b)
end

function scene:find(x, y)
  while x < 1 do x = x + self.columns end
  while x > self.columns do x = x - self.columns end
  while y < 1 do y = y + self.rows end
  while y > self.rows do y = y - self.rows end
  return self.squares[x][y]
end

function scene:enterFrame(event)
  if self.view.alpha < 1 then
    self.view.alpha = math.min(1, self.view.alpha + .03)
  end
  self.cooldown = self.cooldown - 1
  if self.cooldown > 1 then
    return
  end
  self.cooldown = self.CYCLE
  local prev = self.active_row
  local next = (self.active_row % self.rows) + 1
  self.active_row = next
  huecounts = { 0, 0, 0, 0, 0, 0 }
  for i = 1, self.columns do
    local before = self.squares[i][prev]
    local after = self.squares[((i - 2) % self.columns) + 1][prev]
    local square
    if next == 1 then
      square = self.squares[(i - 2) % self.columns + 1][next]
    else
      square = self.squares[i][next]
    end
    local adjust = -2
    if square.flag then
      adjust = -1
      square.flag = nil
    end

    local new = ((before.compute + after.compute + adjust) % self.total_colors) + 1
    square.compute = new
    if square.compute > 1 then
      square.alpha = math.min(1, square.alpha + (.015 * self.rows))
    else
      square.alpha = math.min(1, square.alpha + (.006 * self.rows))
    end
    square.hue = self.colors[square.compute % 2 + 1]
    new = ((new - 1) % #Rainbow.hues) + 1
    huecounts[new] = huecounts[new] + 1
    self:colorize(square)
  end
  self.colors[1] = (self.colors[1] % self.total_colors) + 1
  self.colors[2] = (self.colors[2] % self.total_colors) + 1
  for _, column in ipairs(self.squares) do
    for _, square in ipairs(column) do
      square.alpha = math.max(0, square.alpha - .01)
    end
  end
  local max = 1
  local gt0 = 0
  for i, h in ipairs(huecounts) do
    if h > 0 then
      gt0 = gt0 + 1
    end
    if h > huecounts[max] then
      max = i
    end
  end
  Sounds.play(i)
end

function scene:willEnterScene(event)
  for x = 1, self.columns do
    for y = 1, self.rows do
      self.squares[x][y].hue = 1 + self.COLOR_MULTIPLIER
      self.squares[x][y].compute = 1
      self.squares[x][y].alpha = self.FADED + (y == 1 and 0.1 or 0.0)
      self:colorize(self.squares[x][y])
    end
  end
  self.active_row = 1
  self.index = 0
  self.colors = { 1, 1 + self.COLOR_MULTIPLIER }
  self.squares[1][1].hue = 1
  self:colorize(self.squares[1][1])
  self.squares[1][1].compute = 2
  self.view.alpha = 0
end

function scene:touch_magic(state, ...)
  if state.ordered[1] then
    local x, y = state.ordered[1].current.x, state.ordered[1].current.y
    x = math.ceil((x + 1) / self.square_size)
    y = math.ceil((y + 1) / self.square_size)
    local square = self.squares[x][y]
    square.flag = true
    square.hue = square.hue + self.COLOR_MULTIPLIER
    self:colorize(square)
  end
  return true
end

function scene:enterScene(event)
  self.toward = nil
  Runtime:addEventListener('enterFrame', scene)
  self.view:addEventListener('touch', Touch.handler(self.touch_magic, self))
end

function scene:didExitScene(event)
  self.view.alpha = 0
end

function scene:exitScene(event)
  self.toward = nil
  Runtime:removeEventListener('enterFrame', scene)
  self.view:removeEventListener('touch', Touch.handler(self.touch_magic, self))
end

function scene:destroyScene(event)
  self.squares = nil
  self.sheet = nil
  self.igroup:removeSelf()
  self.igroup = nil
end

scene:addEventListener('createScene', scene)
scene:addEventListener('enterScene', scene)
scene:addEventListener('willEnterScene', scene)
scene:addEventListener('exitScene', scene)
scene:addEventListener('didExitScene', scene)
scene:addEventListener('destroyScene', scene)

return scene
