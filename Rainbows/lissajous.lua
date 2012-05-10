local storyboard = require('storyboard')
local scene = storyboard.newScene()

scene.HISTORY = 8
scene.COLOR_MULTIPLIER = 16
scene.LINE_MULTIPLIER = 16
scene.point_total = #Rainbow.hues * scene.COLOR_MULTIPLIER
scene.line_total = scene.point_total - 1
scene.FRAME_DELAY = 3
scene.SOUND_DELAY = 3
scene.DELTA_DELTA = 0.02 * scene.FRAME_DELAY
scene.INSET = 4

local rfuncs = Rainbow.funcs_for(scene.COLOR_MULTIPLIER)
local colorfor = rfuncs.smooth
local colorize = rfuncs.smoothobj

local pi = math.pi
local ceil = math.ceil
local twopi = pi * 2
local sin = math.sin
local cos = math.cos
local sqrt = math.sqrt
local min = math.min
local max = math.max
local abs = math.abs
local fmod = math.fmod
local frame = Util.enterFrame
local touch = Touch.state

local s

function scene:createScene(event)
  self.ids = self.ids or {}
  self.sorted_ids = self.sorted_ids or {}
  self.toward = self.toward or {}

  s = Screen.new(self.view)
  self.x_scale = s.size.x / 2 - (scene.INSET / 2)
  self.y_scale = s.size.y / 2 - (scene.INSET / 2)

  self.x_offset = self.x_scale + (scene.INSET / 2)
  self.y_offset = self.y_scale + (scene.INSET / 2)

  self.lines = {}
  self.cooldown = 0
  self.a = 1
  self.b = 1
  self.delta = 1
  self.line_scale = twopi / self.line_total
  -- so clicks have something to land on
  self.bg = display.newRect(s, 0, 0, s.size.x, s.size.y)
  self.bg:setFillColor(0, 0)
  s:insert(self.bg)
  self.view.alpha = 0
end

function scene:line(color, g)
  if not color then
    color = self.next_color or 1
  end
  g = g or display.newGroup()
  g.segments = g.segments or {}
  if #g.segments == self.line_total then
    for i, seg in ipairs(g.segments) do
      seg:setPoints(self.vecs[i], self.vecs[i + 1])
      colorize(seg, color)
      seg:redraw()
      color = color + 1
    end
  else
    for i = 1, self.line_total do
      local seg = g.segments[i]
      local point = self.vecs[i]
      local next = self.vecs[i + 1]
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
  self.next_color = (color % scene.line_total) + 1
  return g
end

function scene:calc(quiet)
  self.vecs = self.vecs or {}
  if self.target_a and self.a ~= self.target_a then
    if self.a < self.target_a then
      self.a = min(self.target_a, self.a + .06250 * self.scale_delta_a)
    else
      self.a = max(self.target_a, self.a - .06250 * self.scale_delta_a)
    end
    if self.a == self.target_a then
      self.target_a = nil
    end
  end
  if self.target_b and self.b ~= self.target_b then
    if self.b < self.target_b then
      self.b = min(self.target_b, self.b + .06250 * self.scale_delta_b)
    else
      self.b = max(self.target_b, self.b - .06250 * self.scale_delta_b)
    end
    if self.b == self.target_b then
      self.target_b = nil
    end
  end
  self.sign_x = self.sign_x or {}
  self.sign_y = self.sign_y or {}
  self.sound_cooldown = self.sound_cooldown or 0
  local play_sound = false
  for i = 1, self.point_total do
    local t = i * self.line_scale
    local x = sin(self.a * t + self.delta)
    local y = sin(self.b * t - self.delta)
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
    Sounds.play(ceil(self.next_color / self.COLOR_MULTIPLIER))
    self.sound_cooldown = self.SOUND_DELAY
  else
    self.sound_cooldown = self.sound_cooldown - 1
  end
  local delta_scale = max(max(abs(self.b), abs(self.a)), 1)
  self.delta = self.delta + self.DELTA_DELTA / delta_scale
  if self.delta > twopi then
    self.delta = self.delta - twopi
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
  end
  self.cooldown = self.FRAME_DELAY
  local last = table.remove(self.lines, 1)
  for i, l in ipairs(self.lines) do
    l.alpha = sqrt(i / self.HISTORY)
  end
  self:calc()
  table.insert(self.lines, scene:line(nil, last))
  self.lines[#self.lines].alpha = 1
end

function scene:willEnterScene(event)
  self.view.alpha = 0
  self.cooldown = 0
end

function scene:enterScene(event)
  touch(nil)
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
    local l = self:line(i, nil)
    l.alpha = sqrt(i / scene.HISTORY)
    table.insert(self.lines, l)
    s:insert(l)
    l.y = 0
    self:calc(true)
  end
  self.next_color = 1
  Runtime:addEventListener('enterFrame', scene)
end


function scene:touch_magic(state)
  local point
  local lowest
  for i, v in pairs(state.points) do
    if not lowest or i < lowest then
      lowest = i
      point = v
    end
  end
  if point and point.current then
    local x = point.current.x - s.origin.x
    local y = point.current.y - s.origin.y
    local ta = (ceil(x * 8 / s.size.x) - 4) / 2
    local tb = ceil(y * 8 / s.size.y) / 2 + 1
    -- local origa, origb = ta, tb
    local sign_a = ta < 0 and -1 or 1
    if abs(ta) < 1 then
      ta = sign_a
    end
    -- avoid degenerate cases
    local integer_a = fmod(ta, 1) == 0 or fmod(ta, tb) == 0
    local integer_b = fmod(tb, 1) == 0 or fmod(tb, ta) == 0
    local multiples = (fmod(ta, tb) == 0 or fmod(tb, ta) == 0)
    -- if either is a multiple of the other, and neither is 1 exactly,
    -- we'll get redraw/overlap which looks lame
    if multiples and (abs(ta) > 1 and tb > 1) then
      if integer_a then
        ta = ta + 0.5 * sign_a
      else
        tb = tb + 0.5
      end
    end
    self.scale_delta_a = max(1, ta - self.a)
    self.scale_delta_b = max(1, tb - self.b)
    self.target_a = ta
    self.target_b = tb
  end
end

function scene:didExitScene(event)
  self.view.alpha = 0
end

function scene:exitScene(event)
  self.sorted_ids = {}
  self.toward = {}
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
