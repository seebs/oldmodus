local Line = {}

local frame = Util.line
local max = math.max
local min = math.min
local deg = math.deg

function Line.new(x1, y1, x2, y2, depth, r, g, b)
  local p1, p2
  if type(x1) == 'table' then
    p1 = { x = x1.x, y = x1.y }
    p2 = { x = y1.x, y = y1.y }
    b = r
    g = depth
    r = y2
    depth = x2 or 1
  else
    p1 = { x = x1, y = y1 }
    p2 = { x = x2, y = y2 }
    depth = depth or 1
  end
  if not b then
    r, g, b = unpack(Rainbow.color(r))
  end
  local o = display.newGroup()
  o.hue = hue or math.random(#Rainbow.hues)
  o.r, o.g, o.b, o.a = r, g, b, 1
  o.depth = depth
  if o.depth < 1 then
    o.depth = 1
  end
  o.lines = {}
  for i = 1, o.depth do
    local l = display.newRect(o, 0, 0, 1, 1)
    l.alpha = max(0, min(1, 1.5 / o.depth))
    o:insert(l)
    table.insert(o.lines, l)
  end
  o.blendMode = 'add'
  o.thickness = o.depth
  o.thick_scale = 1
  o.p1 = p1
  o.p2 = p2
  o.setPoints = Line.setPoints
  o.setThickness = Line.setThickness
  o.setAlpha = Line.setAlpha
  o.setColor = Line.setColor
  o.redraw = Line.redraw
  return o
end

function Line:setAlpha(a)
  self.a = a
end

function Line:setPoints(p1, p2)
  self.p1 = { x = p1.x, y = p1.y }
  self.p2 = { x = p2.x, y = p2.y }
end

function Line:setThickness(thickness)
  self.thickness = thickness
  self.thick_scale = self.thickness / self.depth
end

function Line:setColor(r, g, b, a)
  self.r, self.g, self.b, self.a = r, g, b, (a or 255)
end

function Line:redraw()
  local f = frame(self.p1, self.p2)
  self.x, self.y = f.x, f.y
  for i, l in ipairs(self.lines) do
    l.xScale = f.len + .0001
    l.yScale = i * self.thick_scale
    l:setFillColor(self.r, self.g, self.b, self.a)
    l.blendMode = 'add'
  end
  self.rotation = deg(f.theta)
end

return Line
