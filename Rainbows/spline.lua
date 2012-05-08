local storyboard = require('storyboard')
local scene = storyboard.newScene()

scene.COLOR_MULTIPLIER = 6
-- scene.line_total = #Rainbow.hues * scene.COLOR_MULTIPLIER
scene.HISTORY = 16
scene.LINE_DELAY = 2
scene.TOTAL_COLORS = #Rainbow.hues * scene.COLOR_MULTIPLIER
scene.LINE_SEGMENTS = scene.TOTAL_COLORS
scene.VELOCITY_MIN = 5
scene.VELOCITY_MAX = 15
scene.START_POINTS = 4
scene.TOUCH_ACCEL = 1

local rfuncs = Rainbow.funcs_for(scene.COLOR_MULTIPLIER)
local colorfor = rfuncs.smooth
local colorize = rfuncs.smoothobj
local midpoint = Util.midpoint
local partway = Util.partway
local ceil = math.ceil

local s

function scene:createScene(event)
  self.ids = self.ids or {}
  self.sorted_ids = self.sorted_ids or {}
  self.toward = self.toward or {}

  self.lines = {}
  
  s = Screen.new(self.view)

  -- so clicks have something to land on

  self.bg = display.newRect(s, 0, 0, s.size.x, s.size.y)
  self.bg:setFillColor(0, 0)
  s:insert(self.bg)
  self.view.alpha = 0
end

function scene:spline(vecs, points, lo, hi)
  if lo == hi then
    return
  end
  local mid = ceil((lo + hi) / 2)
  local midpt = midpoint(vecs[2], vecs[3])
  local p = points[mid + 1] or {}
  p.x, p.y = midpt.x, midpt.y
  points[mid + 1] = p
  if mid == lo or mid == hi then
    return
  end
  local newvecs = {
    vecs[1],
    midpoint(vecs[1], vecs[2]),
    partway(vecs[2], vecs[3], .25),
    midpt,
    partway(vecs[2], vecs[3], .75),
    midpoint(vecs[3], vecs[4]),
    vecs[4]
  }
  -- if mid == lo+1, then this would just overwrite it
  if mid ~= lo + 1 then
    scene:spline(newvecs, points, lo, mid)
  end
  if mid ~= hi - 1 then
    scene:spline({ newvecs[4], newvecs[5], newvecs[6], newvecs[7] }, points, mid, hi)
  end
end

function scene:line(color, g)
  if not color then
    color = self.next_color or 1
    self.next_color = (color % scene.TOTAL_COLORS) + 1
  end
  g = g or display.newGroup()
  g.points = g.points or {}
  g.segments = g.segments or {}
  scene:spline(self.vecs, g.points, 0, self.LINE_SEGMENTS)
  g.points[1] = { x = self.vecs[1].x, y = self.vecs[1].y }
  g.points[self.LINE_SEGMENTS + 1] = { x = self.vecs[4].x, y = self.vecs[4].y }
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

function scene:one_line(color, vec1, vec2, existing)
  if not vec1 or not vec2 then
    return nil
  end
  if not existing then
    local l = Line.new(vec1, vec2, 2, colorfor(color))
    l:setThickness(2)
    return l
  else
    existing:setPoints(vec1, vec2)
    colorize(existing, color)
    return existing
  end
end

function scene:move()
  local bounce = false
  for i, v in ipairs(self.vecs) do
    if v:move(self.toward[i]) then
      bounce = true
    end
  end
  -- not used during startup
  if bounce and self.next_color then
    Sounds.play(ceil(self.next_color / self.COLOR_MULTIPLIER))
  end
end

function scene:enterFrame(event)
  Util.enterFrame()
  if self.view.alpha < 1 then
    self.view.alpha = math.min(self.view.alpha + .01, 1)
  end
  if self.cooldown > 1 then
    self.cooldown = self.cooldown - 1
    return
  else
    self.cooldown = self.LINE_DELAY
  end
  local last = table.remove(self.lines, 1)
  for i, l in ipairs(self.lines) do
    l.alpha = math.sqrt(i / self.HISTORY)
  end
  table.insert(self.lines, scene:line(nil, last))
  self.lines[#self.lines].alpha = 1
  self:move()
end

function scene:willEnterScene(event)
  self.view.alpha = 0
  self.cooldown = 0
end

function scene:enterScene(event)
  self.lines = {}
  self.next_color = nil
  self.vecs = {}
  for i = 1, scene.START_POINTS do
    self.vecs[i] = Vector.new(s, self)
  end
  self:move()
  for i = 1, scene.HISTORY do
    local l = self:line(i, nil)
    l.alpha = math.sqrt(i / scene.HISTORY)
    table.insert(self.lines, l)
    self:move()
  end
  self.next_color = 1
  Runtime:addEventListener('enterFrame', scene)
  Touch.handler(self.touch_magic, self)
end

function scene:touch_magic(state, ...)
  self.toward = {}
  if state.active > 0 and state.phase ~= 'ended' then
    local lookup = { 1, 4, 2, 3 }
    for i, v in ipairs(state.ordered) do
      self.toward[lookup[i] or 5] = v.current
    end
  end
  return true
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
  Touch.handler()
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
