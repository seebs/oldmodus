local storyboard = require('storyboard')
local scene = storyboard.newScene()

local frame = Util.enterFrame
local touch = Touch.state

scene.KNIGHTS = 6

scene.FADED = 0.75
scene.CYCLE = 12
-- NOT necessarily .KNIGHTS
scene.FADE_DIVISOR = 5 * scene.CYCLE

function scene:createScene(event)
  s = Screen.new(self.view)
  self.squares = Squares.new(s, self.KNIGHTS)
  self.knights = {}
end

function scene:setcolor(square, hue)
  if square then
    square:colorize(hue)
  end
end

function scene:bump(square, hue)
  if square then
    square:colorize(Rainbow.towards(square.hue, hue))
    if square.alpha < scene.FADED then
      square.alpha = (scene.FADED + square.alpha) / 2
    end
  end
end

function scene:adjust(knight, quiet)
  local square = self.squares[knight.x][knight.y]
  scene:setcolor(square, knight.hue)
  square.alpha = 1
  if knight.light then
    knight.light:move(square)
    knight.light.isVisible = true
  end
  if not quiet then
    Sounds.play(square.hue)
  end
  square.alpha = 1
  scene:bump(square:find(1, 0), knight.hue)
  scene:bump(square:find(-1, 0), knight.hue)
  scene:bump(square:find(0, 1), knight.hue)
  scene:bump(square:find(0, -1), knight.hue)
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
  frame()
  touch(self.touch_magic, self)
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
      square.hue = (x + y) % #Rainbow.hues
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
      hue = ((i - 1) % #Rainbow.hues) + 1,
      cooldown = self.CYCLE,
      light = self.squares.highlights[i]
    }
    knight.light.hue = knight.hue
    knight.light:colorize()
    table.insert(self.knights, knight)
    self:adjust(knight, true)
  end
  self.view.alpha = 0
end

function scene:touch_magic(state, ...)
  self.toward = {}
  for i, v in pairs(state.points) do
    if not v.done then
      self.toward[i] = self.squares:from_screen(v.current)
    end
  end
  return true
end

function scene:enterScene(event)
  touch(nil)
  Runtime:addEventListener('enterFrame', scene)
end

function scene:didExitScene(event)
  self.view.alpha = 0
end

function scene:exitScene(event)
  Runtime:removeEventListener('enterFrame', scene)
end

function scene:destroyScene(event)
  self.squares = nil
  self.sheet = nil
  self.igroup:removeSelf()
  self.igroup = nil
  self.knights = nil
end

scene:addEventListener('createScene', scene)
scene:addEventListener('enterScene', scene)
scene:addEventListener('willEnterScene', scene)
scene:addEventListener('exitScene', scene)
scene:addEventListener('didExitScene', scene)
scene:addEventListener('destroyScene', scene)

return scene
