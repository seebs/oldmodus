local scene = {}

scene.meta = {
  name = "Knights",
  description = "Glowing squares perform random knight's moves, advancing colors towards their own."
}

scene.KNIGHTS = 6

scene.FADED = 0.75

local s
local set

function scene:createScene(event)
  s = self.screen
  set = self.settings

  self.squares = Squares.new(s, set, self.KNIGHTS)
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
    if square.alpha < self.FADED then
      square.alpha = (self.FADED + square.alpha) / 2
    end
  end
end

function scene:adjust(knight)
  local square = self.squares[knight.x][knight.y]
  local oldhue = square.hue
  scene:setcolor(square, knight.hue)
  square.alpha = 1
  if knight.light then
    knight.light:move(square)
    knight.light.isVisible = true
  end
  if knight.index % 3 == 1 then
    Sounds.playexact(knight.index + self.tone_offset, 1)
    if knight.index == 4 then
      self.tone_offset = (self.tone_offset + 1) % 3
    end
  end
  Sounds.playexact(oldhue + 5, 0.8)
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

  self.squares[knight.x][knight.y].alpha = self.FADED + 0.1

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
  local knight = self.knights[1]
  self:move_knight(knight)
  table.remove(self.knights, 1)
  table.insert(self.knights, knight)
  if knight.index == 1 then
    for _, column in ipairs(self.squares) do
      for _, square in ipairs(column) do
	square.alpha = math.max(0, square.alpha - .003)
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
  self.tone_offset = 0
  self.knights = {}
  for i = 1, self.KNIGHTS do
    local knight = {
      x = math.random(self.squares.columns),
      y = math.random(self.squares.rows),
      index = i,
      hue = ((i - 1) % #Rainbow.hues) + 1,
      light = self.squares.highlights[i]
    }
    knight.light.hue = knight.hue
    knight.light:colorize()
    table.insert(self.knights, knight)
    self:adjust(knight)
  end
end

function scene:touch_magic(state, ...)
  self.toward = {}
  for i, v in pairs(state.points) do
    if not v.done then
      self.toward[i] = self.squares:from_screen(v.current)
    end
  end
end

function scene:enterScene(event)
  self.toward = {}
  self.tone_offset = 0
end

function scene:destroyScene(event)
  self.squares:removeSelf()
  self.squares = nil
  self.knights = nil
end

return scene
