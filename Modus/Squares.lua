local Squares = {}

local ceil = math.ceil
local floor = math.floor
local max = math.max
local min = math.min
local sqrt = math.sqrt
local tinsert = table.insert
local tremove = table.remove

Squares.sheet = graphics.newImageSheet("square.png", { width = 128, height = 128, numFrames = 3 })

function Squares.colorize(square, color)
  square.hue = color or square.hue
  square:setFillColor(square.squares.color(square.hue))
  -- square:setStrokeColor(square.squares.color(square.hue))
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
  x = x - self.x_offset
  y = y - self.y_offset
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

function Squares.new(group, set, args)
  args = args or {}
  highlights = args.highlights or 0
  multiplier = args.multiplier or set.color_multiplier or 1
  square_type = args.square_type or set.square_type or 2
  local squares = {}

  -- purely arbitrary guess
  if not set.max_items then
    set.max_items = 1300
  end
  -- temporary to do a first-pass calculation
  local divisor = 1
  local try = 24
  while true do
    squares.square_size = try
    squares.rows = floor(group.size.y / squares.square_size)
    squares.columns = floor(group.size.x / squares.square_size)
    squares.total_squares = squares.rows * squares.columns
    local too_tall = squares.rows / 35
    local too_wide = squares.columns / 35
    local too_many = squares.total_squares / set.max_items
    local too_big = max(too_tall, max(too_wide, too_many))
    if too_big > 1 then
      try = max(floor(try * sqrt(too_big)) - 1, try + 1)
      Util.printf("%.1f, %.1f, %.1f: too big, now try %d",
        too_tall, too_wide, too_many, try)
    else
      break
    end
  end

  -- Util.printf("Trying %d divisor, square size %.1f.", squares.square_divisor, squares.square_size)
  -- center display
  if squares.rows * squares.square_size < group.size.y then
    local diff = group.size.y - (squares.rows * squares.square_size)
    squares.y_offset = diff / 2
    group.y = group.y + squares.y_offset
  else
    squares.y_offset = 0
  end
  if squares.columns * squares.square_size < group.size.x then
    local diff = group.size.x - (squares.columns * squares.square_size)
    squares.x_offset = diff / 2
    group.x = group.x + squares.x_offset
  else
    squares.x_offset = 0
  end
  squares.r = {}
  squares.igroup = display.newGroup()
  group:insert(squares.igroup)
  squares.igroup.x = 0
  squares.igroup.y = 0
  squares.igroup:setReferencePoint(display.TopLeftReferencePoint)
  local funcs = Rainbow.funcs_for(multiplier or set.color_multiplier or 1)
  squares.color = funcs.smooth
  squares.multiplier = multiplier
  squares.square_type = square_type
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
      local square = display.newImage(Squares.sheet, squares.square_type)
      square.blendMode = 'add'
      -- local square = display.newRect(0, 0, squares.square_size * .8, squares.square_size * .8)
      -- square.strokeWidth = squares.square_size * .2
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
  if highlights and highlights > 0 then
    for i = 1, highlights do
      local light = display.newImage(Squares.sheet, squares.square_type)
      light:scale(squares.square_size / 256, squares.square_size / 256)
      -- local light = display.newRect(0, 0, squares.square_size * 0.5, squares.square_size * 0.5)
      -- light.strokeWidth = squares.square_size * 0.1
      light.isVisible = false
      light.blendMode = 'add'
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
