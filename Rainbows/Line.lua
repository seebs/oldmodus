local Line = {}

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
  Line.sheet = Line.sheet or graphics.newImageSheet('pixel.png', {
    width = 16, height = 16, numFrames = 1
  })
  local o = display.newGroup()
  o.hue = hue or math.random(#Rainbow.hues)
  o.r, o.g, o.b, o.a = r, g, b, 255
  o.depth = depth
  if o.depth < 1 then
    o.depth = 1
  end
  o.lines = {}
  for i = 1, o.depth do
    local l = display.newRect(o, 0, 0, 1, 1)
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
  o:redraw()
  return o
end

function Line:setAlpha(a)
  o.a = a
  self:redraw()
end

function Line:setPoints(x1, y1, x2, y2)
  if type(x1) == 'table' then
    self.p1 = { x = x1.x, y = x1.y }
    self.p2 = { x = y1.x, y = y1.y }
  else
    self.p1 = { x = x1, y = y1 }
    self.p2 = { x = x2, y = y2 }
  end
  self:redraw()
end

function Line:setThickness(thickness)
  self.thickness = thickness
  self.thick_scale = self.thickness / self.depth
  self:redraw()
end

function Line:setColor(r, g, b, a)
  self.r, self.g, self.b, self.a = r, g, b, (a or 255)
  self:redraw()
end

function Line:redraw()
  local frame = Util.line(self.p1, self.p2)
  self.x, self.y = frame.x, frame.y
  for i, l in ipairs(self.lines) do
    l.xScale = frame.len + .0001
    l.yScale = i * self.thick_scale
    l.alpha = math.max(0, math.min(1, 1.5 / self.depth))
    l:setFillColor(self.r, self.g, self.b, self.a)
    l.blendMode = 'add'
  end
  self.rotation = math.deg(frame.theta)
end

return Line
