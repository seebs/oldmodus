local storyboard = require('storyboard')
local scene = storyboard.newScene()

scene.HISTORY = 12
scene.LINE_MULTIPLIER = 16
scene.line_total = #Rainbow.hues * scene.LINE_MULTIPLIER
scene.FRAME_DELAY = 2
scene.SOUND_DELAY = 3
scene.DELTA_DELTA = 0.04 * scene.FRAME_DELAY
scene.INSET = 4

function scene:new_vec(void)
  return {
    x = 0,
    y = 0,
  }
end

function scene:createScene(event)
  self.ids = self.ids or {}
  self.sorted_ids = self.sorted_ids or {}
  self.toward = self.toward or {}

  self.lines = {}
  self.cooldown = 0
  self.a = 1
  self.b = 1
  self.delta = 1
  self.line_scale = math.pi * 2 / (self.line_total - 1)
  self.x_scale = (screen.width / 2) - scene.INSET
  self.y_scale = (screen.height / 2) - scene.INSET
  self.x_offset = scene.x_scale + screen.xoff + (scene.INSET / 2)
  self.y_offset = scene.y_scale + screen.yoff + (scene.INSET / 2)
  -- so clicks have something to land on
  self.bg = display.newRect(self.view, screen.xoff, screen.yoff, screen.width, screen.height)
  self.bg:setFillColor(0, 0)
  self.view:insert(self.bg)
  self.view.alpha = 0
end

function scene:line(color)
  local g = display.newGroup()
  if not color then
    color = self.next_color or 1
  end
  for i = 1, #self.vecs - 1 do
    local l = self:one_line(color, self.vecs[i], self.vecs[i + 1])
    color = color + 1
    if l then
      g:insert(l)
    end
  end
  self.next_color = (color + 2) % scene.line_total
  return g
end

function scene:one_line(color, vec1, vec2)
  if not vec1 or not vec2 then
    return nil
  end
  if not color then
    color = self.next_color or 1
    self.next_color = (color % scene.line_total) + 1
  end
  local r, g, b = unpack(Rainbow.smooth(color, scene.LINE_MULTIPLIER))
  local l
  local rect

  if vec1.x ~= vec2.x or vec1.y ~= vec2.y then
    rect = {
      x = (vec1.x + vec2.x) / 2,
      y = (vec1.y + vec2.y) / 2,
      len = Util.dist(vec1, vec2) - 0.5,
      angle = math.atan2(vec2.y - vec1.y, vec2.x - vec1.x),
    }
  else
    rect = {
      x = (vec1.x + vec2.x) / 2,
      y = (vec1.y + vec2.y) / 2,
      len = Util.dist(vec1, vec2) - 0.5,
      angle = 0
    }
  end
  local i = 3
  l = display.newRect(
    0 - (rect.len / 2),
    0 - (i / 2),
    rect.len,
    i)
  l.x = rect.x
  l.y = rect.y
  l:setFillColor(r, g, b)
  l.blendMode = "add"
  l.rotation = math.deg(rect.angle)

  return l
end

function scene:calc(quiet)
  self.vecs = self.vecs or {}
  if self.target_a and self.a ~= self.target_a then
    if self.a < self.target_a then
      self.a = math.min(self.target_a, self.a + .06250 * self.scale_delta_a)
    else
      self.a = math.max(self.target_a, self.a - .06250 * self.scale_delta_a)
    end
    if self.a == self.target_a then
      self.target_a = nil
    end
  end
  if self.target_b and self.b ~= self.target_b then
    if self.b < self.target_b then
      self.b = math.min(self.target_b, self.b + .06250 * self.scale_delta_b)
    else
      self.b = math.max(self.target_b, self.b - .06250 * self.scale_delta_b)
    end
    if self.b == self.target_b then
      self.target_b = nil
    end
  end
  self.sign_x = self.sign_x or {}
  self.sign_y = self.sign_y or {}
  self.sound_cooldown = self.sound_cooldown or 0
  local play_sound = false
  for i = 1, self.line_total do
    local t = i * self.line_scale
    local x = math.sin(self.a * t + self.delta)
    local y = math.sin(self.b * t - self.delta)
    if not quiet and i % self.LINE_MULTIPLIER == 0 then
      local new_sign_x = x < 0
      local new_sign_y = y < 0
      if new_sign_x ~= self.sign_x[i] or new_sign_y ~= self.sign_y[i] then
        play_sound = true
      end
      self.sign_x[i] = new_sign_x
      self.sign_y[i] = new_sign_y
    end
    x = x * self.x_scale + self.x_offset
    y = y * self.y_scale + self.y_offset
    self.vecs[i] = self.vecs[i] or {}
    self.vecs[i].x = x
    self.vecs[i].y = y
  end
  if play_sound and self.sound_cooldown < 1 then
    Sounds.play(self.last_color)
    self.sound_cooldown = self.SOUND_DELAY
  else
    self.sound_cooldown = self.sound_cooldown - 1
  end
  local delta_scale = math.sqrt(math.max(1, math.abs(self.a)) * math.max(1, math.abs(self.b)))
  self.delta = self.delta + self.DELTA_DELTA / delta_scale
  if self.delta > math.pi * 2 then
    self.delta = self.delta - math.pi * 2
  end
end

function scene:enterFrame(event)
  if self.view.alpha < 1 then
    self.view.alpha = math.min(self.view.alpha + .01, 1)
  end
  if self.cooldown > 1 then
    self.cooldown = self.cooldown - 1
    return
  end
  self.cooldown = self.FRAME_DELAY
  local last = table.remove(self.lines, 1)
  if last then
    last:removeSelf()
  end
  for i, l in ipairs(self.lines) do
    l.alpha = i / self.HISTORY
  end
  self:calc()
  table.insert(self.lines, scene:line())
end

function scene:willEnterScene(event)
  self.view.alpha = 0
  self.cooldown = 0
end

function scene:enterScene(event)
  self.lines = {}
  self.next_color = nil
  self.a = 2
  self.b = 3
  self.target_a = 2
  self.target_b = 3
  self.scale_delta_a = 1
  self.scale_delta_b = 1
  self:calc(true)
  for i = 1, scene.HISTORY do
    local l = self:line(i)
    l.alpha = i / scene.HISTORY
    table.insert(self.lines, l)
    self:calc(true)
  end
  self.next_color = 1
  Runtime:addEventListener('enterFrame', scene)
  self.view:addEventListener('touch', Touch.handler(self.touch_magic, self))
end

function scene:touch_magic(state, ...)
  local point = state.ordered[1]
  if point and point.current then
    local x = point.current.x - screen.xoff
    local y = point.current.y - screen.yoff
    local ta = (math.ceil(x * 8 / screen.width) - 4) / 2
    local tb = math.ceil(y * 8 / screen.height) / 2 + 1
    -- local origa, origb = ta, tb
    local sign_a = ta < 0 and -1 or 1
    if math.abs(ta) < 1 then
      ta = sign_a
    end
    -- avoid degenerate cases
    local integer_a = math.fmod(ta, 1) == 0 or math.fmod(ta, tb) == 0
    local integer_b = math.fmod(tb, 1) == 0 or math.fmod(tb, ta) == 0
    local multiples = (math.fmod(ta, tb) == 0 or math.fmod(tb, ta) == 0)
    -- if either is a multiple of the other, and neither is 1 exactly,
    -- we'll get redraw/overlap which looks lame
    if multiples and (math.abs(ta) > 1 and tb > 1) then
      if integer_a then
        ta = ta + 0.5 * sign_a
      else
        tb = tb + 0.5
      end
    end
    self.scale_delta_a = math.max(1, ta - self.a)
    self.scale_delta_b = math.max(1, tb - self.b)
    self.target_a = ta
    self.target_b = tb
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
