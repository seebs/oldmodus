local storyboard = require('storyboard')
local scene = storyboard.newScene()

scene.LINE_MULTIPLIER = 8
scene.line_total = #Rainbow.hues * scene.LINE_MULTIPLIER
scene.LINE_DELAY = 2
scene.VELOCITY_MIN = 10
scene.VELOCITY_MAX = 20
scene.START_LINES = 1
scene.LINE_DEPTH = 8
scene.TOUCH_ACCEL = 1

local s

function scene:createScene(event)
  self.ids = self.ids or {}
  self.sorted_ids = self.sorted_ids or {}
  self.toward = self.toward or {}

  s = Screen.new(self.view)

  self.lines = {}
  -- so clicks have something to land on
  self.bg = display.newRect(s, 0, 0, s.size.x, s.size.y)
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
    g.segments[i]:redraw()
  end
  if #self.vecs > 2 then
    if g.segments[#self.vecs] then
      self:one_line(color, self.vecs[#self.vecs], self.vecs[1], g.segments[#self.vecs])
    else
      local l = self:one_line(color, self.vecs[#self.vecs], self.vecs[1])
      g.segments[#self.vecs] = l
      g:insert(l)
    end
    g.segments[#self.vecs]:redraw()
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
    if v:move(self.toward[i]) then
      bounce = true
    end
  end
  -- not used during startup
  if bounce and self.next_color then
    Sounds.play(math.ceil(self.next_color / self.LINE_MULTIPLIER))
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
  table.insert(self.lines, scene:line(nil, last))
  self:move()
end

function scene:willEnterScene(event)
  self.view.alpha = 0
  self.cooldown = self.LINE_DELAY
end

function scene:enterScene(event)
  self.lines = {}
  self.next_color = nil
  self.vecs = {}
  s = Screen.new(self.view)
  for i = 1, scene.START_LINES + 1 do
    self.vecs[i] = Vector.new(s, self)
  end
  for i = 1, scene.line_total do
    local l = self:line(i, nil)
    self:move()
    table.insert(self.lines, l)
  end
  self.next_color = 1
  self.last_color = scene.line_total
  Runtime:addEventListener('enterFrame', scene)
  Touch.handler(self.touch_magic, self)
end

function scene:touch_magic(state, ...)
  self.toward = {}
  if state.active > 0 and state.phase ~= 'ended' then
    for i, v in ipairs(state.ordered) do
      self.toward[i] = v.current
    end
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
