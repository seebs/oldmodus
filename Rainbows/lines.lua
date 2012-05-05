local storyboard = require('storyboard')
local scene = storyboard.newScene()

scene.LINE_MULTIPLIER = 8
scene.line_total = #Rainbow.hues * scene.LINE_MULTIPLIER
scene.LINE_SPEED = 2
scene.VELOCITY_MIN = 10
scene.VELOCITY_MAX = 20
scene.VELOCITY_VARIANCE = scene.VELOCITY_MAX - scene.VELOCITY_MIN
scene.START_LINES = 1
scene.LINE_DEPTH = 8
scene.TOUCH_ACCEL = 1

function scene:random_velocity()
  local d = math.random(self.VELOCITY_VARIANCE) + self.VELOCITY_MIN
  if math.random(2) == 2 then
    d = d * -1
  end
  return d
end

function scene:new_vec(void)
  return {
    x = math.random(screen.width) - 1,
    y = math.random(screen.height) - 1,
    dx = scene:random_velocity(),
    dy = scene:random_velocity(),
  }
end

function scene:createScene(event)
  self.ids = self.ids or {}
  self.sorted_ids = self.sorted_ids or {}
  self.toward = self.toward or {}

  self.lines = {}
  -- so clicks have something to land on
  self.bg = display.newRect(self.view, screen.xoff, screen.yoff, screen.width, screen.height)
  self.bg:setFillColor(0, 0)
  self.view:insert(self.bg)
  self.view.alpha = 0
end

function scene:line(color, g)
  if not color then
    color = self.next_color or 1
    self.next_color = (color % scene.line_total) + 1
  end
  g = g or display.newGroup()
  g.segments = g.segments or {}
  for i = 1, #self.vecs - 1 do
    if g.segments[i] then
      self:one_line(color, self.vecs[i], self.vecs[i + 1], g.segments[i])
    else
      local l = self:one_line(color, self.vecs[i], self.vecs[i + 1])
      g.segments[i] = l
      g:insert(l)
    end
  end
  if #self.vecs > 2 then
    if g.segments[#self.vecs] then
      self:one_line(color, self.vecs[#self.vecs], self.vecs[1], g.segments[#self.vecs])
    else
      local l = self:one_line(color, self.vecs[#self.vecs], self.vecs[1])
      g.segments[#self.vecs] = l
      g:insert(l)
    end
  end
  while #g.segments > #self.vecs or (#g.segments > 1 and #self.vecs == 2) do
    local l = table.remove(g.segments)
    l:removeSelf()
  end
  return g
end

function scene:one_line(color, vec1, vec2, existing)
  if not vec1 or not vec2 then
    return nil
  end
  if not existing then
    local l = Line.new(vec1, vec2, 5, unpack(Rainbow.smooth(color, self.LINE_MULTIPLIER)))
    l:setThickness(3)
    return l
  else
    existing:setPoints(vec1, vec2)
    existing:setColor(unpack(Rainbow.smooth(self.next_color, self.LINE_MULTIPLIER)))
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
    Sounds.play(math.ceil(self.next_color / self.LINE_MULTIPLIER))
  end
end

function scene:move_vec(vec, id)
  local bounce_x, bounce_y = false, false
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
    self.cooldown = 2
  end
  local last = table.remove(self.lines, 1)
  table.insert(self.lines, scene:line(nil, last))
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
  for i = 1, scene.START_LINES + 1 do
    self.vecs[i] = self:new_vec(void)
  end
  for i = 1, scene.line_total do
    local l = self:line(i, nil)
    self:move()
    table.insert(self.lines, l)
  end
  self.next_color = 1
  self.last_color = scene.line_total
  Runtime:addEventListener('enterFrame', scene)
  self.view:addEventListener('touch', Touch.handler(self.touch_magic, self))
end

function scene:touch_magic(state, ...)
  self.toward = {}
  for i, v in ipairs(state.ordered) do
    self.toward[i] = v.current
  end

  while #state.ordered > #self.vecs do
    table.insert(self.vecs, self:new_vec())
  end
  if #state.ordered == 0 and state.peak < #self.vecs and #self.vecs > 2 then
    table.remove(self.vecs, 1)
  end
  return true
end

function scene:didExitScene(event)
  self.view.alpha = 0
  for i, l in ipairs(self.lines) do
    l:removeSelf()
  end
  self.lines = {}
end

function scene:exitScene(event)
  self.sorted_ids = {}
  self.toward = {}
  self.view:removeEventListener('touch', Touch.handler(self.touch_magic, self))
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
