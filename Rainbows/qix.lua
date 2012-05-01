local storyboard = require('storyboard')
local scene = storyboard.newScene()

scene.LINE_MULTIPLIER = 8
scene.line_total = #Rainbow.hues * scene.LINE_MULTIPLIER
scene.LINE_SPEED = 2
scene.VELOCITY_MIN = 10
scene.VELOCITY_MAX = 20
scene.VELOCITY_VARIANCE = scene.VELOCITY_MAX - scene.VELOCITY_MIN

function scene:random_velocity()
  local d = math.random(self.VELOCITY_VARIANCE) + self.VELOCITY_MIN
  if math.random(2) == 2 then
    d = d * -1
  end
  return d
end

function scene:createScene(event)
  self.lines = {}
  -- so clicks have something to land on
  self.bg = display.newRect(self.view, screen.xoff, screen.yoff, screen.width, screen.height)
  self.bg:setFillColor(0, 0)
  self.view:insert(self.bg)
  self.vec1 = {
    x = math.random(screen.width) - 1,
    y = math.random(screen.height) - 1,
    dx = scene:random_velocity(),
    dy = scene:random_velocity(),
  }
  self.vec2 = {
    x = math.random(screen.width) - 1,
    y = math.random(screen.height) - 1,
    dx = scene:random_velocity(),
    dy = scene:random_velocity(),
  }
  for i = 1, scene.line_total do
    local l = self:line(i)
    self:move()
    table.insert(self.lines, l)
  end
  self.next_color = 1
  Util.printf("lines: %d", #self.lines)
  self.last_color = scene.line_total
  self.view.alpha = 0
end

function scene:line(color)
  if not color then
    color = self.next_color or 1
    self.next_color = (color % scene.line_total) + 1
  end
  local r, g, b = unpack(Rainbow.smooth(color, scene.LINE_MULTIPLIER))
  local gr = {}
  local l
  local rect

  if self.vec1.x ~= self.vec2.x or self.vec1.y ~= self.vec2.y then
    rect = {
      x = (self.vec1.x + self.vec2.x) / 2,
      y = (self.vec1.y + self.vec2.y) / 2,
      len = Util.dist(self.vec1, self.vec2),
      angle = math.atan2(self.vec2.y - self.vec1.y, self.vec2.x - self.vec1.x),
    }
  else
    rect = {
      x = (self.vec1.x + self.vec2.x) / 2,
      y = (self.vec1.y + self.vec2.y) / 2,
      len = Util.dist(self.vec1, self.vec2),
      angle = 0
    }
  end
  for i = 5, 1, -1 do
    l = display.newRect(self.view,
      rect.x - (rect.len / 2),
      rect.y - (i / 2),
      rect.len + i,
      i)
    l:setFillColor(r, g, b, 60)
    l.blendMode = "add"
    l.rotation = math.deg(rect.angle)
    self.view:insert(l)
    table.insert(gr, l)
  end

  return gr
end

function scene:move()
  local bounce = false
  if self:move_vec(self.vec1) then
    bounce = true
  end
  if self:move_vec(self.vec2) then
    bounce = true
  end
  -- not used during startup
  if bounce and self.next_color then
    Sounds.play(math.ceil(self.next_color / self.LINE_MULTIPLIER))
  end
end

function scene:move_vec(vec)
  local bounce_x, bounce_y = false, false

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
    vec.dx = vec.dx * -1
    if vec.dx >= scene.VELOCITY_MAX then
      vec.dx = vec.dx - (math.random(2) - 1)
    elseif vec.dx <= scene.VELOCITY_MIN then
      vec.dx = vec.dx + (math.random(2) - 1)
    else
      vec.dx = vec.dx + (math.random(3) - 2)
    end
  end

  if bounce_y then
    vec.dy = vec.dy * -1
    if vec.dy >= scene.VELOCITY_MAX then
      vec.dy = vec.dy - (math.random(2) - 1)
    elseif vec.dy <= scene.VELOCITY_MIN then
      vec.dy = vec.dy + (math.random(2) - 1)
    else
      vec.dy = vec.dy + (math.random(3) - 2)
    end
  end
  return bounce_x or bounce_y
end

function scene:enterFrame(event)
  if self.view.alpha < 1 then
    self.view.alpha = math.min(self.view.alpha + .01, 1)
  end
  local last = table.remove(self.lines, 1)
  for i, l in pairs(last) do
    l:removeSelf()
  end
  local l = scene:line()
  table.insert(self.lines, l)
  self:move()
end

function scene:willEnterScene(event)
  self.view.alpha = 0
  self.cooldown = 0
end

function scene:enterScene(event)
  Runtime:addEventListener('enterFrame', scene)
  self.view:addEventListener('touch', next_display)
end

function scene:didExitScene(event)
  self.view.alpha = 0
end

function scene:exitScene(event)
  self.view:removeEventListener('touch', next_display)
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
