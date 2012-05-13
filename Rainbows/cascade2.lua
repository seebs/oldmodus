local scene = {}

scene.FADED = 0.75

local max = math.max
local min = math.min

local s
local set

function scene:createScene(event)
  s = self.screen
  set = self.settings
  self.squares = Squares.new(s, 0, set.color_multiplier)
  self.total_colors = #Rainbow.hues * set.color_multiplier
end

function scene:enterFrame(event)
  self.toggle = not self.toggle

  if self.toggle then
    local last = self.squares.r[self.squares.rows]
    last.flag = 0
    self.squares:shift(0, -1)
    last = self.squares.r[self.squares.rows]
    last.flag = 0
    self.colors[1] = (self.colors[1] % self.total_colors) + 1
    self.colors[2] = (self.colors[2] % self.total_colors) + 1
    last.colors = { unpack(self.colors) }
  end

  local prow = nil
  local flags = {}
  local sound_effect = 0
  for y, row in ipairs(self.squares.r) do
    prow = self.squares.r[y - 1]
    if self.toggle then
      for i, square in ipairs(row) do
	square.alpha = max(0.005, square.alpha - .01)
      end
    end
    local process = false
    if row.flag < 0 then
      row.flag = row.flag * -1
    end
    if y == self.squares.rows and self.toggle then
      process = true
    end
    if prow and prow.flag > 0 then
      process = true
      if row.flag == 0 then
        row.flag = -1 * prow.flag
	prow.flag = 0
      end
    end
    if process then
      local previous_state = 0
      local toggles = 0
      for i, square in ipairs(row) do
	-- shift left occasionally
	if row.colors[1] % set.color_multiplier == 0 then
	  square = square:find(-1, 0)
	end
	local after = prow[i]
	local before = after:find(-1, 0)

	square.compute = (before.compute + after.compute) % 2
	square.hue = row.colors[square.compute + 1]
	square:colorize()
	square.flag = nil

	if square.compute ~= previous_state then
	  previous_state = square.compute
	  toggles = toggles + 1
	end
	if square.compute == 1 then
	  -- square.alpha = min(1, square.alpha + (.03 * self.squares.rows))
	  square.alpha = 1
	else
	  -- only do this for the new bottom row
	  if y == self.squares.rows and self.toggle then
	    square.alpha = min(1, square.alpha + (.004 * self.squares.rows))
	  end
	end
      end
      sound_effect = toggles
    end
  end
  if self.toggle then
    Sounds.play(sound_effect)
  end
end

function scene:willEnterScene(event)
  self.colors = {
    self.total_colors - self.squares.rows,
    self.total_colors - self.squares.rows + set.color_multiplier
  }
  for y, row in ipairs(self.squares.r) do
    row.colors = { unpack(self.colors) }
    row.flag = 0
    for x, square in ipairs(row) do
      square.hue = row.colors[1]
      square.compute = 0
      square.alpha = self.FADED + (1 - self.FADED) * (y / self.squares.rows)
      square.flag = false
      square:colorize()
    end
    self.colors[1] = (self.colors[1] % self.total_colors) + 1
    self.colors[2] = (self.colors[2] % self.total_colors) + 1
  end
  self.index = 0
  local square = self.squares:find(1, 0)
  if square then
    square.hue = square.row.colors[2]
    square:colorize()
    square.compute = 1
  end
end

function scene:touch_magic(state)
  if state.events > 0 then
    for i, e in pairs(state.points) do
      if e.events > 0 then
        local hitboxes = {}
	local square
	for i, p in ipairs(e.previous) do
	  square = self.squares:from_screen(p)
	  if square then
	    -- Util.printf("previous: %d, %d", square.logical_x, square.logical_y)
	    hitboxes[square] = true
	  end
	end
	square = self.squares:from_screen(e.current)
	if square then
	  -- Util.printf("current: %d, %d", square.logical_x, square.logical_y)
	  hitboxes[square] = true
	end
	for square, _ in pairs(hitboxes) do
	  if not square.flag then
	    square.row.flag = 1
	    square.alpha = 1
	    square.flag = true
	    square.compute = square.compute + 1
	    square.hue = square.hue + set.color_multiplier
	    square:colorize()
	  end
	end
      end
    end
  end
end

function scene:enterScene(event)
  self.toward = nil
  self.toggle = false
end

function scene:exitScene(event)
  self.toward = nil
end

function scene:destroyScene(event)
  self.squares:removeSelf()
  self.squares = nil
end

return scene
