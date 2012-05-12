local Hexes = {}

Hexes.x_to_y = 224 / 256

Hexes.hex_size = math.max(32, Util.gcd(Screen.size.x, Screen.size.y))
while (Screen.size.x / Hexes.hex_size < 13) and Hexes.hex_size % 2 == 0 do
  Hexes.hex_size = Hexes.hex_size / 2
end
Hexes.per_hex_horizontal = Hexes.hex_size * 3 / 4
Hexes.hex_vertical = Hexes.x_to_y * Hexes.hex_size
Hexes.horizontal_quarter = Hexes.hex_size / 4
Hexes.vertical_half = Hexes.hex_vertical / 2
Hexes.per_hex_vertical = Hexes.vertical_half

local floor = math.floor
local ceil = math.ceil
local abs = math.abs
local fmod = math.fmod

-- this gets fussy; if you divide a hex into four equal parts, each additional
-- hex costs three fourths as much.  So if size were 32, it'd be 32, 32+24,
-- 32+48, etc.
function Hexes.horizontal_in(x)
  local quarters = x * 4 / Hexes.hex_size
  return math.floor((quarters - 1) / 3)
end

-- same deal; every two hexes costs you a full hex in height, but there's
-- an initial extra half
function Hexes.vertical_in(y)
  local halves = y * 2 / Hexes.hex_vertical
  return math.floor((halves - 1) / 2)
end

Hexes.rows = Hexes.vertical_in(Screen.size.y)
Hexes.columns = Hexes.horizontal_in(Screen.size.x)
Hexes.directions = { 'north', 'northeast', 'southeast', 'south', 'southwest', 'northwest' }
Hexes.sheet = graphics.newImageSheet("hex.png", { width = 256, height = 224, numFrames = 1 })

function Hexes.colorize(hex, color)
  hex.hue = color or hex.hue
  hex:setFillColor(hex.hexes.color(hex.hue))
end

function Hexes.find(hexes, x, y)
  x = ((x - 1) % Hexes.columns) + 1
  y = ((y - 1) % Hexes.rows) + 1
  return hexes[x][y]
end

function Hexes.north(hex)
  return hex:find(0, -1)
end

function Hexes.south(hex)
  return hex:find(0, 1)
end

function Hexes.northeast(hex)
  return hex:find(1, hex.high and -1 or 0)
end

function Hexes.southeast(hex)
  return hex:find(1, hex.high and 0 or 1)
end

function Hexes.northwest(hex)
  return hex:find(-1, hex.high and -1 or 0)
end

function Hexes.southwest(hex)
  return hex:find(-1, hex.high and 0 or 1)
end

function Hexes.here(hex)
  return hex
end

function Hexes.hex_towards(hex1, hex2)
  local dx = hex2.logical_x - hex1.logical_x
  local dy = hex2.logical_y - hex1.logical_y
  local sign_x = dx > 0 and 1 or (dx < 0 and -1 or 0)
  local sign_y = dy > 0 and 1 or (dy < 0 and -1 or 0)
  if abs(dx) > hex1.hexes.columns / 2 then
    sign_x = 0 - sign_x
  end
  if abs(dy) > hex1.hexes.rows / 2 then
    sign_y = 0 - sign_y
  end
  if hex1.low and sign_x ~= 0 and sign_y == -1 then
    sign_y = 0
  elseif hex1.high and sign_x ~= 0 and sign_y == 1 then
    sign_y = 0
  end
  local dir, new = Hexes.direction_to(hex1, sign_x, sign_y), hex1.hexes:find(hex1.logical_x + sign_x, hex1.logical_y + sign_y)
  -- Util.printf("From %d, %d to %d, %d: (%d, %d) %s, %d, %d",
  --   hex1.logical_x, hex1.logical_y, hex2.logical_x, hex2.logical_y, sign_x, sign_y, dir, new.logical_x, new.logical_y)
  return dir, new
end

function Hexes.direction_to(hex, sign_x, sign_y)
  if sign_x == 0 then
    if sign_y < 0 then
      return 'north'
    elseif sign_y > 0 then
      return 'south'
    else
      return 'here'
    end
  elseif sign_x < 0 then
    if sign_y < 0 or hex.low then
      return 'northwest'
    elseif sign_y > 0 or hex.high then
      return 'southwest'
    end
  elseif sign_x > 0 then
    if sign_y < 0 or hex.low then
      return 'northeast'
    elseif sign_y > 0 or hex.high then
      return 'southeast'
    end
  end
end

Hexes.go = {
  north = Hexes.north,
  south = Hexes.south,
  northeast = Hexes.northeast,
  southeast = Hexes.southeast,
  northwest = Hexes.northwest,
  southwest = Hexes.southwest,
}

Hexes.dir = {
  here = Hexes.here,
  north = Hexes.north,
  south = Hexes.south,
  northeast = Hexes.northeast,
  southeast = Hexes.southeast,
  northwest = Hexes.northwest,
  southwest = Hexes.southwest,
}

Hexes.turn = {
  north = {
    ahead = "north",
    right = "northeast",
    hard_right = "southeast",
    left = "northwest",
    hard_left = "southwest",
    back = "south",
  },
  northeast = {
    ahead = "northeast",
    right = "southeast",
    hard_right = "south",
    left = "north",
    hard_left = "northwest",
    back = "southwest",
  },
  southeast = {
    ahead = "southeast",
    right = "south",
    hard_right = "southwest",
    left = "northeast",
    hard_left = "north",
    back = "northwest",
  },
  south = {
    ahead = "south",
    right = "southwest",
    hard_right = "northwest",
    left = "southeast",
    hard_left = "northeast",
    back = "north",
  },
  southwest = {
    ahead = "southwest",
    right = "northwest",
    hard_right = "north",
    left = "south",
    hard_left = "southeast",
    back = "northeast",
  },
  northwest = {
    ahead = "northwest",
    right = "north",
    hard_right = "northeast",
    left = "southwest",
    hard_left = "south",
    back = "southeast",
  }
}

function Hexes.splash(hex, mindepth, maxdepth, proc, ...)
  local paths = { }
  for i = 1, maxdepth do
    for k, f in pairs(Hexes.go) do
      paths[k] = f(paths[k] or hex)
      if i >= mindepth then
	coroutine.resume(proc, paths[k], i, ...)
	local g = Hexes.dir[Hexes.turn[k].hard_right]
	local h
	for j = 1, i - 1 do
	  h = g(h or paths[k])
	  coroutine.resume(proc, h, i, ...)
	end
      end
    end
  end
  coroutine.resume(proc, false)
end

function Hexes:from_screen(t_or_x, y)
  local x
  if type(t_or_x) == 'table' then
    x = t_or_x.x
    y = t_or_x.y
  else
    x = t_or_x
  end
  local x_insquare = fmod(x, Hexes.per_hex_horizontal) / Hexes.per_hex_horizontal
  -- should run 0-to-1, with 1 for the edges and 0 for the middle
  local y_insquare = fmod(y, Hexes.hex_vertical) - Hexes.vertical_half
  local y_away = abs(y_insquare) / Hexes.vertical_half
  x = floor(x / Hexes.per_hex_horizontal)
  y = floor(y / Hexes.hex_vertical)
  if x % 2 == 1 then
    if x_insquare < 0.2 and y_away < x_insquare then
      x = x - 1
    else
      if y_insquare < 0 then
        y = y - 1
      end
    end
  else
    if y_away > x_insquare * 3 then
      x = x - 1
      if y_insquare < 0 then
	y = y - 1
      end
    end
  end
  return self:find(x + 1, y + 1)
end

function Hexes:shift_hexes(x, y)
  -- shuffle hexes within their rows
  if x then
    x = x % self.columns
    if x > 0 then
      for idx, row in ipairs(self.r) do
        local newrow = {}
	for _, hex in ipairs(row) do
	  local ex = x
	  if _ + x > self.columns then
	    ex = ex - self.columns
	  end
	  local height_change = (ex % 2) == 1
	  hex.logical_x = hex.logical_x + ex
	  newrow[hex.logical_x] = hex
	  hex.x = hex.x + (ex * Hexes.per_hex_horizontal)
	  if height_change then
	    if hex.low then
	      hex.low = false
	      hex.high = true
	      hex.y = 0
	    else
	      hex.high = false
	      hex.low = true
	      hex.y = Hexes.per_hex_vertical
	    end
	  end
	  hex.column = self[hex.logical_x]
	end
	for idx, hex in ipairs(newrow) do
	  row[idx] = hex
	end
      end
      while x > 0 do
        table.insert(self, 1, table.remove(self))
	x = x - 1
      end
      for idx, h in ipairs(self.highlights) do
        h:move(h.hex)
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
	row.y = row.y + (ey * Hexes.hex_vertical)
	for _, hex in ipairs(row) do
	  hex.logical_y = hex.logical_y + ey
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
        h:move(h.hex)
      end
    end
  end
end

function Hexes.find_from(hex, x, y)
  return Hexes.find(hex.hexes, hex.logical_x + x, hex.logical_y + y)
end

function Hexes.move_highlight(light, hex)
  if hex then
    light.x = hex.x + Hexes.hex_size / 2
    light.y = hex.row.y + hex.y
    light.hex = hex
    light.isVisible = true
  end
end

function Hexes.new(group, highlights, multiplier)
  local hexes = {}
  hexes.rows = Hexes.rows
  hexes.columns = Hexes.columns
  hexes.r = {}
  hexes.igroup = display.newGroup()
  group:insert(hexes.igroup)
  hexes.igroup.x = 0
  hexes.igroup.y = 0
  hexes.igroup:setReferencePoint(display.TopLeftReferencePoint)
  local funcs = Rainbow.funcs_for(multiplier or 1)
  hexes.color = funcs.smooth
  hexes.color_towards = funcs.towards
  hexes.color_dist = funcs.dist
  hexes.multiplier = multiplier
  hexes.highlights = {}
  hexes.width = Screen.size.x
  hexes.height = Screen.size.y
  hexes.shift = Hexes.shift_hexes
  hexes.from_screen = Hexes.from_screen
  for y = 1, Hexes.rows do
    local row
    if not hexes.r[y] then
      -- if imagegroups start working better:
      -- row = display.newImageGroup(Hexes.sheet)
      row = display.newGroup()
      hexes.igroup:insert(row)
      row.x = Hexes.hex_size / 2
      row.y = (y - 0.5) * Hexes.hex_vertical
      hexes.r[y] = row
    else
      row = hexes.r[y]
    end
    for x = 1, Hexes.columns do
      hexes[x] = hexes[x] or {}
      local hex = display.newImage(Hexes.sheet, 1)
      row:insert(hex)
      hex.x = (x - 1) * Hexes.per_hex_horizontal
      if x % 2 == 0 then
        hex.y = Hexes.per_hex_vertical
	hex.low = true
      else
	hex.high = true
        hex.y = 0
      end
      hex.xScale = Hexes.hex_size / 256
      hex.yScale = Hexes.hex_size / 256
      hex.logical_x = x
      hex.logical_y = y
      hex.hue = 0
      hex.row = row
      hex.column = hexes[x]
      hex.hexes = hexes
      hex.colorize = Hexes.colorize
      hex.find = Hexes.find_from
      hex.dir = Hexes.dir
      hex.towards = Hexes.hex_towards
      hex.splash = Hexes.splash
      hexes[x][y] = hex
      -- so ipairs will think it's a table with pairs
      table.insert(hexes.r[y], hex)
    end
  end
  hexes.find = Hexes.find
  if highlights then
    for i = 1, highlights do
      local light = display.newImage(Hexes.sheet, 1)
      light.xScale = Hexes.hex_size / 512
      light.yScale = Hexes.hex_size / 512
      light.isVisible = false
      hexes.igroup:insert(light)
      light.alpha = .8
      light.move = Hexes.move_highlight
      light.colorize = Hexes.colorize
      light.hexes = hexes
      table.insert(hexes.highlights, light)
    end
  end
  return hexes
end

return Hexes
