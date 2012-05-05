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
  self.cooldown = self.CYCLE
  self.total_colors = #Rainbow.hues * self.COLOR_MULTIPLIER
  for i = 1, self.rows do
    local g = display.newImageGroup(self.sheet)
    local row = { group = g, colors = { 1, 1 }, flag = 0 }
    self.view:insert(g)
    g.isVisible = true
    for j = 1, self.columns do
      local square = display.newImage(self.sheet, 1)
      square:scale(self.square_size / 128, self.square_size / 128)
      g:insert(square)
      square:setReferencePoint(display.TopLeftReferencePoint)
      square.x = (#row * self.square_size)
      square.y = 0
      square.isVisible = true
      row[j] = square
    end
    g:setReferencePoint(display.TopLeftReferencePoint)
    g.x = 0
    g.y = screen.yoff + #self.squares * self.square_size
    self.squares[i] = row
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
  return self.squares[y][x]
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
  self.toggle = not self.toggle

  if self.toggle then
    local first = table.remove(self.squares, 1)
    self.colors[1] = (self.colors[1] % self.total_colors) + 1
    self.colors[2] = (self.colors[2] % self.total_colors) + 1
    first.colors = { unpack(self.colors) }
    local last = self.squares[#self.squares]
    last.flag = 0
    first.flag = 0
    table.insert(self.squares, first)
    first.group.y = #self.squares * self.square_size + screen.yoff
  end

  local prow = nil
  for y, row in ipairs(self.squares) do
    prow = self.squares[y - 1]
    if self.toggle then
      row.group.y = row.group.y - self.square_size
      for i, square in ipairs(row) do
	square.alpha = math.max(0.005, square.alpha - .01)
      end
    end
    if row.flag < 0 then
      row.flag = row.flag * -1
    end
    if (prow and prow.flag > 0) or y == self.rows then
      if row.flag == 0 and prow.flag > 0 then
        row.flag = -1 * prow.flag
	prow.flag = 0
      end
      for i, square in ipairs(row) do
	local before = prow[i]
	local after = prow[((i - 2) % self.columns) + 1]
	local adjust = -2
	if row.colors[1] % self.COLOR_MULTIPLIER == 0 then
	  square = row[(i - 2) % self.columns + 1]
	end
	if square.flag then
	  adjust = -1
	end

	local new = ((before.compute + after.compute + adjust) % self.total_colors) + 1
	square.compute = new
	square.hue = row.colors[square.compute % 2 + 1]
	self:colorize(square)
      end
    end
    if row.flag < 0 or (y == self.rows and self.toggle) then
      for x, square in ipairs(row) do
	square.flag = nil
	if square.compute % 2 ~= 1 then
	  -- square.alpha = math.min(1, square.alpha + (.03 * self.rows))
	  square.alpha = 1
	else
	  -- only do this if we weren't specially-processing this row
	  if row.flag >= 0 then
	    square.alpha = math.min(1, square.alpha + (.004 * self.rows))
	  end
	end
      end
    end
  end
  Sounds.play()
end

function scene:willEnterScene(event)
  self.colors = {
    self.total_colors - self.rows,
    self.total_colors - self.rows + self.COLOR_MULTIPLIER
  }
  self.colors[1] = (self.colors[1] % self.total_colors) + 1
  self.colors[2] = (self.colors[2] % self.total_colors) + 1
  for y, row in ipairs(self.squares) do
    row.colors = { unpack(self.colors) }
    row.flag = 0
    for x = 1, self.columns do
      local square = row[x]
      square.hue = row.colors[2]
      square.compute = 1
      square.alpha = self.FADED + (1 - self.FADED) * (y / self.rows)
      square.flag = 0
      self:colorize(square)
    end
    self.colors[1] = (self.colors[1] % self.total_colors) + 1
    self.colors[2] = (self.colors[2] % self.total_colors) + 1
  end
  self.index = 0
  self.squares[self.rows][1].hue = 1
  self:colorize(self.squares[self.rows][1])
  self.squares[self.rows][1].compute = 2
  self.view.alpha = 0
end

function scene:touch_magic(state, ...)
  if state.ordered[1] then
    local x, y = state.ordered[1].current.x, state.ordered[1].current.y
    x = math.ceil((x + 1) / self.square_size)
    y = math.ceil((y + 1) / self.square_size)
    local square = self.squares[y][x]
    self.squares[y].flag = self.squares[y].flag + 1
    square.flag = true
    square.compute = square.compute + 1
    square.hue = square.hue + self.COLOR_MULTIPLIER
    self:colorize(square)
  end
  return true
end

function scene:enterScene(event)
  self.toward = nil
  self.toggle = false
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
