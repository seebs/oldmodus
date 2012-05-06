
local storyboard = require('storyboard')
local scene = storyboard.newScene()

scene.COLOR_MULTIPLIER = 12
-- scene.line_total = #Rainbow.hues * scene.COLOR_MULTIPLIER
scene.HISTORY = 12
scene.LINE_DELAY = 2
scene.TOTAL_COLORS = #Rainbow.hues * scene.COLOR_MULTIPLIER
scene.LINE_SEGMENTS = scene.TOTAL_COLORS
scene.VELOCITY_MIN = 5
scene.VELOCITY_MAX = 15
scene.VELOCITY_VARIANCE = scene.VELOCITY_MAX - scene.VELOCITY_MIN
scene.THETA_MIN = 6 * math.pi
scene.THETA_MAX = 6 * math.pi
scene.THETA_VARIANCE = scene.THETA_MAX - scene.THETA_MIN
scene.POINTS = 2
scene.TOUCH_ACCEL = 1
scene.ROTATIONS = 1

function scene:random_velocity()
  local d = math.random(self.VELOCITY_VARIANCE) + self.VELOCITY_MIN
  if math.random(2) == 2 then
    d = d * -1
  end
  return d
end

function scene:random_theta()
  local t = math.random() * self.THETA_VARIANCE + self.THETA_MIN
  return t
end

function scene:new_vec(void)
  return {
    x = math.random(screen.width) - 1,
    y = math.random(screen.height) - 1,
    dx = scene:random_velocity(),
    dy = scene:random_velocity(),
    theta = scene:random_theta(),
  }
end

function scene:createScene(event)
  self.ids = self.ids or {}
  self.sorted_ids = self.sorted_ids or {}
  self.toward = self.toward or {}

  self.origin = { x = screen.xoff + screen.width / 2, y = screen.yoff + screen.height / 2 }
  self.lines = {}
  -- so clicks have something to land on
  self.bg = display.newRect(self.view, screen.xoff, screen.yoff, screen.width, screen.height)
  self.bg:setFillColor(0, 0)
  self.view:insert(self.bg)
  self.view.alpha = 0
end

function scene:spiral_from(vec, points, segments)
  local params = Util.line(self.origin, vec)
  params.theta = params.theta - math.fmod(vec.theta, math.pi * 2)
  -- no point in doing the 0/N cases, because they're trivial
  for i = 1, segments - 1 do
    local scale = i / segments
    local r = params.len * scale
    local theta = (scale * vec.theta) + params.theta
    points[i + 1] = points[i + 1] or {}
    points[i + 1].x = r * math.cos(theta) + self.origin.x
    points[i + 1].y = r * math.sin(theta) + self.origin.y
  end
end

function scene:all_lines(color, g)
  if not color then
    color = self.next_color or 1
    self.next_color = (color % self.TOTAL_COLORS) + 1
  end
  local color_scale = math.floor(self.TOTAL_COLORS / self.POINTS)
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
  g.points[1] = self.origin
  g.points[self.LINE_SEGMENTS + 1] = { x = self.vecs[index].x, y = self.vecs[index].y }
  for i = 1, self.LINE_SEGMENTS do
    if g.segments[i] then
      self:one_line(color, g.points[i], g.points[i + 1], g.segments[i])
    else
      local l = self:one_line(color, g.points[i], g.points[i + 1])
      g.segments[i] = l
      g:insert(l)
    end
    color = color + 1
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
    local l = Line.new(vec1, vec2, 2, unpack(Rainbow.smooth(color, self.COLOR_MULTIPLIER)))
    l:setThickness(2)
    return l
  else
    existing:setPoints(vec1, vec2)
    existing:setColor(unpack(Rainbow.smooth(color, self.COLOR_MULTIPLIER)))
    return existing
  end
end

function scene:move()
  local bounce = false
  for i, v in ipairs(self.vecs) do
    if self:move_vec(v, i) then
      bounce = true
    end
  end
  -- not used during startup
  if bounce and self.next_color then
    Sounds.play(math.ceil(self.next_color / self.COLOR_MULTIPLIER))
  end
end

function scene:move_vec(vec, id)
  local bounce_x, bounce_y, bounce_theta = false, false, false
  local toward = self.toward[id]

  if toward then
    if toward.x > vec.x then
      vec.dx = vec.dx + self.TOUCH_ACCEL
      if vec.dx == 0 then
        vec.dx = 1
      end
    elseif toward.x < vec.x then
      vec.dx = vec.dx - self.TOUCH_ACCEL
      if vec.dx == 0 then
        vec.dx = -1
      end
    end

    if toward.y > vec.y then
      vec.dy = vec.dy + self.TOUCH_ACCEL
      if vec.dy == 0 then
        vec.dy = 1
      end
    elseif toward.y < vec.y then
      vec.dy = vec.dy - self.TOUCH_ACCEL
      if vec.dy == 0 then
        vec.dy = -1
      end
    end
  end

  vec.x = vec.x + vec.dx
  if vec.x < screen.left then
    bounce_x = true
    vec.x = screen.left + (screen.left - vec.x)
  elseif vec.x > screen.right then
    bounce_x = true
    vec.x = screen.right - (vec.x - screen.right)
  end

  vec.y = vec.y + vec.dy
  if vec.y < screen.top then
    bounce_y = true
    vec.y = screen.top + (screen.top - vec.y)
  elseif vec.y > screen.bottom then
    bounce_y = true
    vec.y = screen.bottom - (vec.y - screen.bottom)
  end

  -- vec.theta = vec.theta + vec.dtheta
  -- if math.abs(vec.theta) > self.THETA_MAX or math.abs(vec.theta) < self.THETA_MIN then
    -- vec.dtheta = vec.dtheta * -1
    -- theta_bounce = true
  -- end

  if bounce_x then
    sign = vec.dx < 0
    vec.dx = vec.dx * (sign and -1 or 1)
    if vec.dx >= scene.VELOCITY_MAX then
      vec.dx = vec.dx - (math.random(2) - 1)
    elseif vec.dx <= scene.VELOCITY_MIN then
      vec.dx = vec.dx + (math.random(2) - 1)
    else
      vec.dx = vec.dx + (math.random(3) - 2)
    end
    vec.dx = vec.dx * (sign and 1 or -1)
  end

  if bounce_y then
    sign = vec.dy < 0
    vec.dy = vec.dy * (sign and -1 or 1)
    if vec.dy >= scene.VELOCITY_MAX then
      vec.dy = vec.dy - (math.random(2) - 1)
    elseif vec.dy <= scene.VELOCITY_MIN then
      vec.dy = vec.dy + (math.random(2) - 1)
    else
      vec.dy = vec.dy + (math.random(3) - 2)
    end
    vec.dy = vec.dy * (sign and 1 or -1)
  end
  return bounce_x or bounce_y
end

function scene:enterFrame(event)
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
  table.insert(self.lines, scene:all_lines(nil, last))
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
  for i = 1, scene.POINTS do
    self.vecs[i] = self:new_vec(void)
    -- self.vecs[i].dtheta = .03
    -- if i % 2 == 1 then
    --   self.vecs[i].theta = self.vecs[i].theta * -1
    --   self.vecs[i].dtheta = self.vecs[i].dtheta * -1
    -- end
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
  Touch.handler(self.touch_magic, self)
end

function scene:touch_magic(state, ...)
  self.toward = {}
  for i, v in ipairs(state.ordered) do
    self.toward[i] = v.current
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
