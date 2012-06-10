local Line = {}

local frame = Util.line
local max = math.max
local min = math.min
local deg = math.deg
local sqrt = math.sqrt
local atan2 = math.atan2
local printf = Util.printf

local redrawn = 0

function Line.redraws()
  printf("redrawn: %d", redrawn)
  redrawn = 0
end

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
  o.r, o.g, o.b, o.a = r, g, b, 255
  o.depth = depth
  o.theta = 0
  if o.depth < 1 then
    o.depth = 1
  end
  o.thickness = o.depth
  o.thick_scale = 1
  o.lines = {}
  for i = 1, o.depth do
    local l = display.newRect(o, 0, 0, 1, 1)
    l.alpha = max(0, min(1, 1.5 / o.depth))
    l.yScale = i * o.thick_scale
    o:insert(l)
    table.insert(o.lines, l)
  end
  o.blendMode = 'add'
  o.p1 = p1
  o.p2 = p2
  o.setPoints = Line.setPoints
  o.setThickness = Line.setThickness
  o.setAlpha = Line.setAlpha
  o.setTheta = Line.setTheta
  o.setColor = Line.setColor
  if o.depth == 1 then
    o.redraw = Line.redraw1
  elseif o.depth == 2 then
    o.redraw = Line.redraw2
  else
    o.redraw = Line.redraw
  end
  o.dirty = true
  return o
end

function Line:setAlpha(a)
  self.a = a
end

function Line:setTheta(theta)
  self.theta = theta
  self.dirty = true
end

function Line:setPoints(p1, p2)
  self.p1 = { x = p1.x, y = p1.y }
  self.p2 = { x = p2.x, y = p2.y }
  self.dirty = true
end

function Line:setThickness(thickness)
  self.thickness = thickness
  self.thick_scale = self.thickness / self.depth
  for i, l in ipairs(self.lines) do
    l.yScale = i * self.thick_scale
  end
end

function Line:setColor(r, g, b, a)
  self.r, self.g, self.b, self.a = r, g, b, (a or 255)
end

function Line:redraw1()
  if self.dirty then
    local ax, bx, ay, by = self.p1.x, self.p2.x, self.p1.y, self.p2.y
    local dx, dy = ax - bx, ay - by
    self.x, self.y, self.len, self.rotation, self.dirty = (ax + bx) / 2, (ay + by) / 2, sqrt(dx * dx + dy * dy), deg(atan2(dy, dx)) + self.theta, false
  end
  self.lines[1]:setFillColor(self.r, self.g, self.b, self.a)
  self.lines[1].blendMode, self.lines[1].xScale = 'add', self.len + .001
  redrawn = redrawn + 1
end

function Line:redraw2()
  if self.dirty then
    local ax, bx, ay, by = self.p1.x, self.p2.x, self.p1.y, self.p2.y
    local dx, dy = ax - bx, ay - by
    self.x, self.y, self.len, self.rotation, self.dirty = (ax + bx) / 2, (ay + by) / 2, sqrt(dx * dx + dy * dy), deg(atan2(dy, dx)) + self.theta, false
  end
  self.lines[1]:setFillColor(self.r, self.g, self.b, self.a)
  self.lines[1].blendMode, self.lines[1].xScale = 'add', self.len + .001
  self.lines[2]:setFillColor(self.r, self.g, self.b, self.a)
  self.lines[2].blendMode, self.lines[2].xScale = 'add', self.len + .001
  redrawn = redrawn + 1
end

function Line:redraw()
  if self.dirty then
    local ax, bx, ay, by = self.p1.x, self.p2.x, self.p1.y, self.p2.y
    local dx, dy = ax - bx, ay - by
    self.x, self.y, self.len, self.rotation, self.dirty = (ax + bx) / 2, (ay + by) / 2, sqrt(dx * dx + dy * dy), deg(atan2(dy, dx)) + self.theta, false
  end
  for i, l in ipairs(self.lines) do
    l:setFillColor(self.r, self.g, self.b, self.a)
    l.blendMode, l.xScale = 'add', self.len + .001
  end
  redrawn = redrawn + 1
end

return Line
