local scene = {}

scene.KNIGHTS = 6

scene.FADED = 0.75

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
    if square.alpha < self.FADED then
      square.alpha = (self.FADED + square.alpha) / 2
    end
  end
end

function scene:adjust(knight, quiet)
  local square = self.squares[knight.x][knight.y]
  self:bump(square)
  self:bump(square)
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
  self:bump(square:find(1, 0))
  self:bump(square:find(-1, 0))
  self:bump(square:find(0, 1))
  self:bump(square:find(0, -1))
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
  local toward = self.toward[knight.index]
  if toward then
    if toward[primary] > knight[primary] then
      p_chance = .8
    elseif toward[primary] < knight[primary] then
      p_chance = .2
    end
    if toward[secondary] > knight[secondary] then
      s_chance = .8
    elseif toward[secondary] < knight[secondary] then
      s_chance = .2
    end
  end

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
	square.alpha = math.max(0, square.alpha - .0001)
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
      index = i,
      light = self.squares.highlights[i]
    }
    if knight.light then
      knight.light.hue = knight.index
      knight.light:colorize()
    end
    table.insert(self.knights, knight)
    self:adjust(knight, true)
  end
  self.frame_cooldown = self.frame_cooldown + 30
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
end

function scene:destroyScene(event)
  self.squares:removeSelf()
  self.squares = nil
  self.knights = nil
end

return scene
