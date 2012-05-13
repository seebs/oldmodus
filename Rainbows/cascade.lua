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
  self.total_colors = set.color_multiplier * #Rainbow.hues
end

function scene:enterFrame(event)
  local dir = system.orientation
  -- Util.printf("%s", tostring(dir))
  local step_back = false
  local row_mod, square_mod
  local square_adjust
  if dir == 'portraitUpsideDown' then
    row_mod = self.squares.rows
    square_mod = self.squares.columns
    square_adjust = 0
    self.active_row = (self.active_row - 1) % row_mod + 1
    prev = self.squares.r[self.active_row]
    next = prev[1]:find(0, -1).row
    self.active_row = (self.active_row - 2) % row_mod + 1
  elseif dir == 'landscapeLeft' then
    row_mod = self.squares.columns
    square_mod = self.squares.rows
    square_adjust = 0
    self.active_row = (self.active_row - 1) % row_mod + 1
    prev = self.squares[self.active_row]
    next = prev[1]:find(1, 0).column
    self.active_row = self.active_row % row_mod + 1
  elseif dir == 'landscapeRight' then
    row_mod = self.squares.columns
    square_mod = self.squares.rows
    square_adjust = -2
    self.active_row = (self.active_row - 1) % row_mod + 1
    prev = self.squares[self.active_row]
    next = prev[1]:find(-1, 0).column
    self.active_row = (self.active_row - 2) % row_mod + 1
  else
    -- portrait and anything else
    row_mod = self.squares.rows
    square_mod = self.squares.columns
    square_adjust = -2
    self.active_row = (self.active_row - 1) % row_mod + 1
    prev = self.squares.r[self.active_row]
    next = prev[1]:find(0, 1).row
    self.active_row = (self.active_row % self.squares.rows) + 1
  end
  if self.active_row == 1 then
    step_back = true
  end
  local previous_state = 0
  local toggles = 0
  for i, square in ipairs(next) do
    local above = prev[i]
    local before = prev[(i + square_adjust) % square_mod + 1]
    if step_back then
      square = next[(i + square_adjust) % square_mod + 1]
    end
    local new = (above.compute + before.compute)
    if square.flag then
      new = new + 1
      square.flag = nil
    end
    new = new % 2
    square.compute = new
    if square.compute ~= previous_state then
      toggles = toggles + 1
      previous_state = square.compute
    end
    if square.compute == 1 then
      square.alpha = 1
      -- math.min(1, square.alpha + (.022 * self.squares.rows))
    else
      square.alpha = min(1, square.alpha + (.0065 * self.squares.rows))
    end
    square.hue = self.colors[square.compute % 2 + 1]
    square:colorize()
  end
  self.colors[1] = (self.colors[1] % self.total_colors) + 1
  local idx = self.colors[1] % set.color_multiplier
  if idx == 0 or idx == set.color_multiplier / 2 then
    Sounds.playexact(2 * self.colors[1] / set.color_multiplier, 0.8)
  end
  self.colors[2] = (self.colors[2] % self.total_colors) + 1
  for _, column in ipairs(self.squares) do
    for _, square in ipairs(column) do
      square.alpha = max(0.005, square.alpha - .01)
    end
  end
  Sounds.play(toggles)
end

function scene:willEnterScene(event)
  for x, column in ipairs(self.squares) do
    for y, square in ipairs(column) do
      square.hue = 1
      square.compute = 0
      square.alpha = self.FADED + (y == 1 and 0.1 or 0.0)
      square:colorize()
    end
  end
  self.active_row = 1
  self.index = 0
  self.colors = { 1, 1 + set.color_multiplier }
  self.squares[1][1].hue = 1 + set.color_multiplier
  self.squares[1][1]:colorize()
  self.squares[1][1].compute = 1
end

function scene:touch_magic(state)
  if state.events > 0 then
    for i, e in pairs(state.points) do
      if e.events > 0 then
        local hitboxes = {}
	local square
	for i, p in ipairs(e.previous) do
	  square = self.squares:from_screen(p)
	  -- Util.printf("previous: %d, %d", square.logical_x, square.logical_y)
	  if square then
	    hitboxes[square] = true
	  end
	end
	square = self.squares:from_screen(e.current)
	if square then
	  -- Util.printf("current: %d, %d", square.logical_x, square.logical_y)
	  hitboxes[square] = true
	end
	for square, _ in pairs(hitboxes) do
	  square.flag = true
	  square.alpha = 1
	  square.hue = square.hue + set.color_multiplier
	  square:colorize()
	end
      end
    end
  end
end

function scene:enterScene(event)
  self.toward = nil
end

function scene:exitScene(event)
  self.toward = nil
end

function scene:destroyScene(event)
  self.squares:removeSelf()
  self.squares = nil
end

return scene
