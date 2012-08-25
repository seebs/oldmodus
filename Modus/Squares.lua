local Squares = {}

local ceil = math.ceil
local floor = math.floor
local sqrt = math.sqrt
local tinsert = table.insert
local tremove = table.remove

Squares.sheet = graphics.newImageSheet("square.png", { width = 128, height = 128, numFrames = 1 })

function Squares.colorize(square, color)
  square.hue = color or square.hue
  square:setFillColor(square.squares.color(square.hue))
end

function Squares.find(squares, x, y)
  x = ((x - 1) % squares.columns) + 1
  y = ((y - 1) % squares.rows) + 1
  return squares[x][y]
end

function Squares:from_screen(t_or_x, y)
  local x
  if type(t_or_x) == 'table' then
    x = t_or_x.x
    y = t_or_x.y
  else
    x = t_or_x
  end
  return self:find(ceil((x / self.square_size) + 0.05), ceil((y / self.square_size) + 0.05))
end

function Squares:shift_squares(x, y)
  -- shuffle squares within their rows
  if x then
    x = x % self.columns
    if x > 0 then
      for idx, row in ipairs(self.r) do
        local newrow = {}
	for _, square in ipairs(row) do
	  local ex = x
	  if _ + x > self.columns then
	    ex = ex - self.columns
	  end
	  square.logical_x = square.logical_x + ex
	  newrow[square.logical_x] = square
	  square.x = square.x + (ex * self.square_size)
	  square.column = self[square.logical_x]
	end
	for idx, square in ipairs(newrow) do
	  row[idx] = square
	end
      end
      while x > 0 do
        tinsert(self, 1, tremove(self))
	x = x - 1
      end
      for idx, h in ipairs(self.highlights) do
        h:move(h.square)
      end
    end
  end
  if y then
    y = y % self.rows
    if y > 0 then
      for idx, row in ipairs(self.r) do
	local ey = y
	if idx + y > self.rows then
	  ey = ey - self.rows
	end
	row.y = row.y + (ey * self.square_size)
	for _, square in ipairs(row) do
	  square.logical_y = square.logical_y + ey
	end
      end
      while y > 0 do
	tinsert(self.r, 1, tremove(self.r))
	for idx, col in ipairs(self) do
	  tinsert(col, 1, tremove(col))
	end
	y = y - 1
      end
      for idx, h in ipairs(self.highlights) do
        h:move(h.square)
      end
    end
  end
end

function Squares.find_from(square, x, y)
  return Squares.find(square.squares, square.logical_x + x, square.logical_y + y)
end

function Squares.move_highlight(light, square)
  if square then
    light.x = square.x + square.squares.square_size / 2
    light.y = square.row.y
    light.square = square
    light.isVisible = true
  end
end

function Squares.new(group, set, highlights, multiplier)
  local squares = {}
  -- group must be a 'screen', complete with its size and origin values.
  squares.base_size = Util.gcd(group.size.x, group.size.y)
  squares.ratio = {
    x = group.size.x / squares.base_size,
    y = group.size.y / squares.base_size
  }
  squares.grid_base = squares.ratio.x * squares.ratio.y
  -- purely arbitrary guess
  if not set.max_items then
    set.max_items = 1300
  end
  squares.grid_multiplier = set.max_items / squares.grid_base
  -- Util.printf("%dx%d screen = %d squares base, we want at most %.1f times that many.",
  --	squares.ratio.x, squares.ratio.y, squares.grid_base, squares.grid_multiplier)
  squares.square_divisor = floor(sqrt(squares.grid_multiplier))
  while squares.ratio.x * squares.square_divisor > 35 or
        squares.ratio.y * squares.square_divisor > 35 do
    squares.square_divisor = squares.square_divisor - 1
  end
  squares.square_size = squares.base_size / squares.square_divisor
  -- Util.printf("Trying %d divisor, square size %.1f.", squares.square_divisor, squares.square_size)
  squares.rows = squares.ratio.y * squares.square_divisor
  squares.columns = squares.ratio.x * squares.square_divisor
  squares.r = {}
  squares.igroup = display.newGroup()
  group:insert(squares.igroup)
  squares.igroup.x = 0
  squares.igroup.y = 0
  squares.igroup:setReferencePoint(display.TopLeftReferencePoint)
  local funcs = Rainbow.funcs_for(multiplier or 1)
  squares.color = funcs.smooth
  squares.multiplier = multiplier
  squares.highlights = {}
  squares.shift = Squares.shift_squares
  squares.from_screen = Squares.from_screen
  for y = 1, squares.rows do
    local row
    if not squares.r[y] then
      -- if imagegroups start working better:
      -- row = display.newImageGroup(Squares.sheet)
      row = display.newGroup()
      squares.igroup:insert(row)
      row.x = squares.square_size / 2
      row.y = (y - 0.5) * squares.square_size
      squares.r[y] = row
    else
      row = squares.r[y]
    end
    for x = 1, squares.columns do
      squares[x] = squares[x] or {}
      local square = display.newImage(Squares.sheet, 1)
      -- local square = display.newRect(0, 0, 256, 256)
      row:insert(square)
      square.x = (x - 1) * squares.square_size
      square.y = 0
      square.xScale = squares.square_size / 128
      square.yScale = squares.square_size / 128
      square.logical_x = x
      square.logical_y = y
      square.hue = 0
      square.row = row
      square.column = squares[x]
      square.squares = squares
      square.colorize = Squares.colorize
      square.find = Squares.find_from
      squares[x][y] = square
      -- so ipairs will think it's a table with pairs
      tinsert(squares.r[y], square)
    end
  end
  squares.find = Squares.find
  squares.removeSelf = Squares.removeSelf
  if highlights then
    for i = 1, highlights do
      local light = display.newImage(Squares.sheet, 1)
      light:scale(squares.square_size / 256, squares.square_size / 256)
      light.isVisible = false
      squares.igroup:insert(light)
      light.alpha = .8
      light.move = Squares.move_highlight
      light.colorize = Squares.colorize
      light.squares = squares
      tinsert(squares.highlights, light)
    end
  end
  return squares
end

function Squares:removeSelf()
  if self.igroup then
    self.igroup:removeSelf()
  end
  self.igroup = nil
  self.r = nil
  self.highlights = nil
end

return Squares
