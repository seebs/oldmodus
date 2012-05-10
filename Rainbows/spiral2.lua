local storyboard = require('storyboard')
local scene = storyboard.newScene()

local pi = math.pi
local fmod = math.fmod
local sin = math.sin
local min = math.min
local cos = math.cos
local floor = math.floor
local ceil = math.ceil
local abs = math.abs
local frame = Util.enterFrame
local touch = Touch.state

scene.COLOR_MULTIPLIER = 10
-- scene.line_total = #Rainbow.hues * scene.COLOR_MULTIPLIER
scene.HISTORY = 6
scene.LINE_DELAY = 2
scene.TOTAL_COLORS = #Rainbow.hues * scene.COLOR_MULTIPLIER
scene.LINE_SEGMENTS = scene.TOTAL_COLORS
scene.SEGMENT_FUDGE = 5
scene.SEGMENTS_TRIANGLE = (scene.LINE_SEGMENTS * scene.LINE_SEGMENTS + scene.LINE_SEGMENTS) / 2 + (scene.LINE_SEGMENTS * scene.SEGMENT_FUDGE)
scene.VELOCITY_MIN = 5
scene.VELOCITY_MAX = 15
scene.THETA_MIN = 5 * pi
scene.THETA_MAX = 5 * pi
scene.THETA_VARIANCE = scene.THETA_MAX - scene.THETA_MIN
scene.POINTS = 3
scene.TOUCH_ACCEL = 1
scene.ROTATIONS = 1

local rfuncs = Rainbow.funcs_for(scene.COLOR_MULTIPLIER)
local colorfor = rfuncs.smooth
local colorize = rfuncs.smoothobj

local s

function scene:random_theta()
  local t = math.random() * self.THETA_VARIANCE + self.THETA_MIN
  return t
end

function scene:createScene(event)
  self.ids = self.ids or {}
  self.sorted_ids = self.sorted_ids or {}
  self.toward = self.toward or {}

  s = Screen.new(self.view)

  self.center = Vector.new(s, self, 5)
  self.center.ripples = {}
  self.center.theta = self:random_theta()
  self.center.x = s.center.x
  self.center.y = s.center.y
  self.lines = {}
  -- so clicks have something to land on
  self.bg = display.newRect(s, 0, 0, s.size.x, s.size.y)
  self.bg:setFillColor(0, 0)
  s:insert(self.bg)
  self.view.alpha = 0
end

function scene:spiral_from(vec, points, segments)
  local params = Util.line(self.center, vec)
  params.theta = params.theta + fmod(vec.theta, pi * 2)
  local rip = {}
  local remove = {}
  for idx, r in ipairs(vec.ripples) do
    if r > 1 then
      rip[r + 5] = -1
      rip[r + 4] = 0
      rip[r + 3] = 1
      rip[r + 2] = 2
      rip[r + 1] = 1
      rip[r] = 0
      rip[r - 1] = -1
      rip[r - 2] = -2
      vec.ripples[idx] = r - 2
    else
      remove[#remove] = idx
    end
  end
  while #remove > 0 do
    table.remove(vec.ripples, table.remove(remove))
  end
  -- no point in doing the 0/N cases, because they're trivial
  local counter = segments
  for i = 1, segments - 1 do
    local scale = i / segments
    counter = counter + (segments - i) + self.SEGMENT_FUDGE
    local theta = ((counter / self.SEGMENTS_TRIANGLE) * vec.theta) + params.theta
    local r = params.len * scale
    if rip[i] then
      r = r * (1 + 0.03 * rip[i])
    end
    points[i + 1] = points[i + 1] or {}
    points[i + 1].x = r * cos(theta) + self.center.x
    points[i + 1].y = r * sin(theta) + self.center.y
  end
end

function scene:all_lines(color, g)
  if not color then
    color = self.next_color or 1
    self.next_color = (color % self.TOTAL_COLORS) + 1
  end
  local color_scale = floor(self.TOTAL_COLORS / self.POINTS)
  g = g or display.newGroup()
  g.sublines = g.sublines or {}
  for i = 1, self.POINTS do
    if not g.sublines[i] then
      g.sublines[i] = scene:line(color + i * color_scale, g.sublines[i], i)
      g:insert(g.sublines[i])
    else
      scene:line(color + i * color_scale, g.sublines[i], i)
    end
  end
  return g
end

function scene:line(color, g, index)
  g = g or display.newGroup()
  g.points = g.points or {}
  g.segments = g.segments or {}
  scene:spiral_from(self.vecs[index], g.points, self.LINE_SEGMENTS)
  g.points[1] = self.center
  g.points[self.LINE_SEGMENTS + 1] = { x = self.vecs[index].x, y = self.vecs[index].y }
  if #g.segments == self.line_segments then
    for i, seg in ipairs(g.segments) do
      seg:setPoints(g.points[i], g.points[i + 1])
      colorize(seg, color)
      seg:redraw()
      color = color + 1
    end
  else
    for i = 1, self.LINE_SEGMENTS do
      local seg = g.segments[i]
      local point = g.points[i]
      local next = g.points[i + 1]
      if seg then
	seg:setPoints(point, next)
	colorize(seg, color)
      else
	local l = Line.new(point, next, 2, colorfor(color))
	l:setThickness(2)
	seg = l
	g.segments[i] = l
	g:insert(l)
      end
      seg:redraw()
      color = color + 1
    end
  end
  return g
end

local vec_add = Util.vec_add
local vec_scale = Util.vec_scale

function scene:move()
  local bounce = false
  local offset = 0
  if self.center.dx then
    self.center:move(self.toward[1] or s.center)
    offset = 1
  end
  for i, v in ipairs(self.vecs) do
    if v:move(self.toward[i + offset]) then
      table.insert(v.ripples, self.LINE_SEGMENTS + 2)
      bounce = true
    end
  end
  -- not used during startup
  if bounce and self.next_color then
    Sounds.play(ceil(self.next_color / self.COLOR_MULTIPLIER))
  end
end

function scene:enterFrame(event)
  frame()
  touch(self.touch_magic, self)
  if self.view.alpha < 1 then
    self.view.alpha = min(self.view.alpha + .01, 1)
  end
  if self.cooldown > 1 then
    self.cooldown = self.cooldown - 1
    return
  else
    self.cooldown = self.LINE_DELAY
  end
  local last = table.remove(self.lines, 1)
  for i, l in ipairs(self.lines) do
    l.alpha = i / self.HISTORY
  end
  table.insert(self.lines, scene:all_lines(nil, last))
  self.lines[#self.lines].alpha = 1
  self:move()
end

function scene:willEnterScene(event)
  self.view.alpha = 0
  self.cooldown = 0
end

function scene:enterScene(event)
  touch(nil)
  self.lines = {}
  self.next_color = nil
  self.vecs = {}
  for i = 1, scene.POINTS do
    self.vecs[i] = Vector.new(s, self)
    self.vecs[i].ripples = {}
    self.vecs[i].theta = self:random_theta()
  end
  self:move()
  for i = 1, scene.HISTORY do
    local g = self:all_lines(i, nil)
    self.view:insert(g)
    g.alpha = i / scene.HISTORY
    table.insert(self.lines, g)
    self:move()
  end
  self.next_color = 1
  Runtime:addEventListener('enterFrame', scene)
end

function scene:touch_magic(state, ...)
  self.toward = {}
  for i, v in pairs(state.points) do
    if not v.done then
      Util.printf("toward[%d] = v [idx %d] %s",
        i, v.idx, tostring(v.done))
      self.toward[i] = v.current
    end
  end
end

function scene:didExitScene(event)
  self.view.alpha = 0
end

function scene:exitScene(event)
  self.sorted_ids = {}
  self.toward = {}
  self.view.alpha = 0
  for i, l in ipairs(self.lines) do
    l:removeSelf()
  end
  self.lines = {}
  Runtime:removeEventListener('enterFrame', scene)
end

function scene:destroyScene(event)
  self.bg = nil
  self.lines = nil
end

scene:addEventListener('createScene', scene)
scene:addEventListener('willEnterScene', scene)
scene:addEventListener('enterScene', scene)
scene:addEventListener('didExitScene', scene)
scene:addEventListener('exitScene', scene)
scene:addEventListener('destroyScene', scene)

return scene
