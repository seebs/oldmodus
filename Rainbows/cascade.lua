local storyboard = require('storyboard')
local scene = storyboard.newScene()

scene.FADED = 0.75
scene.CYCLE = 12
scene.COLOR_MULTIPLIER = 12
scene.TOTAL_COLORS = #Rainbow.hues * scene.COLOR_MULTIPLIER

function scene:createScene(event)
  s = Screen.new(self.view)
  self.squares = Squares.new(s, 0, self.COLOR_MULTIPLIER)
  self.cooldown = self.CYCLE
end

function scene:enterFrame(event)
  Util.enterFrame()
  if self.view.alpha < 1 then
    self.view.alpha = math.min(1, self.view.alpha + .03)
  end
  self.cooldown = self.cooldown - 1
  if self.cooldown > 1 then
    return
  end
  self.cooldown = self.CYCLE
  local prev = self.active_row
  local next = (self.active_row % self.squares.rows) + 1
  self.active_row = next
  huecounts = { 0, 0, 0, 0, 0, 0 }
  for i = 1, self.squares.columns do
    local before = self.squares:find(i - 1, prev)
    local after = self.squares:find(i, prev)
    local square
    if next == 1 then
      square = self.squares:find(i - 1, next)
    else
      square = self.squares:find(i, next)
    end
    local adjust = -2
    if square.flag then
      adjust = -1
      square.flag = nil
    end

    local new = ((before.compute + after.compute + adjust) % self.TOTAL_COLORS) + 1
    square.compute = new
    if square.compute % 2 ~= 1 then
      square.alpha = 1
      -- math.min(1, square.alpha + (.022 * self.squares.rows))
    else
      square.alpha = math.min(1, square.alpha + (.0065 * self.squares.rows))
    end
    square.hue = self.colors[square.compute % 2 + 1]
    new = ((new - 1) % #Rainbow.hues) + 1
    huecounts[new] = huecounts[new] + 1
    square:colorize()
  end
  self.colors[1] = (self.colors[1] % self.TOTAL_COLORS) + 1
  self.colors[2] = (self.colors[2] % self.TOTAL_COLORS) + 1
  for _, column in ipairs(self.squares) do
    for _, square in ipairs(column) do
      square.alpha = math.max(0.005, square.alpha - .01)
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
  for x, column in ipairs(self.squares) do
    for y, square in ipairs(column) do
      square.hue = 1
      square.compute = 1
      square.alpha = self.FADED + (y == 1 and 0.1 or 0.0)
      square:colorize()
    end
  end
  self.active_row = 1
  self.index = 0
  self.colors = { 1 + self.COLOR_MULTIPLIER, 1 }
  self.squares[1][1].hue = 1 + self.COLOR_MULTIPLIER
  self.squares[1][1]:colorize()
  self.squares[1][1].compute = 2
  self.view.alpha = 0
end

function scene:touch_magic(state, ...)
  if state.ordered[1] then
    local point = self.squares:from_screen(state.ordered[1].current)
    local square = self.squares[point.x][point.y]
    if square then
      square.flag = true
      square.alpha = 1
      square.hue = square.hue + self.COLOR_MULTIPLIER
      square:colorize()
    end
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
end

scene:addEventListener('createScene', scene)
scene:addEventListener('enterScene', scene)
scene:addEventListener('willEnterScene', scene)
scene:addEventListener('exitScene', scene)
scene:addEventListener('didExitScene', scene)
scene:addEventListener('destroyScene', scene)

return scene
