local Squares = {}

local ceil = math.ceil

Squares.square_size = math.max(32, Util.gcd(Screen.size.x, Screen.size.y))
while (Screen.size.x / Squares.square_size < 13) and Squares.square_size % 2 == 0 do
  Squares.square_size = Squares.square_size / 2
end
Squares.rows = math.floor(Screen.size.y / Squares.square_size)
Squares.columns = math.floor(Screen.size.x / Squares.square_size)
Squares.sheet = graphics.newImageSheet("square.png", { width = 128, height = 128, numFrames = 1 })

function Squares.colorize(square, color)
  square.hue = color or square.hue
  square:setFillColor(square.squares.color(square.hue))
end

function Squares.find(squares, x, y)
  x = ((x - 1) % Squares.columns) + 1
  y = ((y - 1) % Squares.rows) + 1
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
  return self:find(ceil((x / Squares.square_size) + 0.05), ceil((y / Squares.square_size) + 0.05))
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
	  square.x = square.x + (ex * Squares.square_size)
	  square.column = self[square.logical_x]
	end
	for idx, square in ipairs(newrow) do
	  row[idx] = square
	end
      end
      while x > 0 do
        table.insert(self, 1, table.remove(self))
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
	row.y = row.y + (ey * Squares.square_size)
	for _, square in ipairs(row) do
	  square.logical_y = square.logical_y + ey
	end
      end
      while y > 0 do
	table.insert(self.r, 1, table.remove(self.r))
	for idx, col in ipairs(self) do
	  table.insert(col, 1, table.remove(col))
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
    light.x = square.x + Squares.square_size / 2
    light.y = square.row.y
    light.square = square
    light.isVisible = true
  end
end

function Squares.new(group, highlights, multiplier)
  local squares = {}
  squares.rows = Squares.rows
  squares.columns = Squares.columns
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
  for y = 1, Squares.rows do
    local row
    if not squares.r[y] then
      -- if imagegroups start working better:
      -- row = display.newImageGroup(Squares.sheet)
      row = display.newGroup()
      squares.igroup:insert(row)
      row.x = Squares.square_size / 2
      row.y = (y - 0.5) * Squares.square_size
      squares.r[y] = row
    else
      row = squares.r[y]
    end
    for x = 1, Squares.columns do
      squares[x] = squares[x] or {}
      local square = display.newImage(Squares.sheet, 1)
      -- local square = display.newRect(0, 0, 256, 256)
      row:insert(square)
      square.x = (x - 1) * Squares.square_size
      square.y = 0
      square.xScale = Squares.square_size / 128
      square.yScale = Squares.square_size / 128
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
      table.insert(squares.r[y], square)
    end
  end
  squares.find = Squares.find
  squares.removeSelf = Squares.removeSelf
  if highlights then
    for i = 1, highlights do
      local light = display.newImage(Squares.sheet, 1)
      light:scale(Squares.square_size / 256, Squares.square_size / 256)
      light.isVisible = false
      squares.igroup:insert(light)
      light.alpha = .8
      light.move = Squares.move_highlight
      light.colorize = Squares.colorize
      light.squares = squares
      table.insert(squares.highlights, light)
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
