local storyboard = require('storyboard')
local scene = storyboard.newScene()

scene.DROPS = #Rainbow.hues * 3
scene.DROP_DEPTH = 12
scene.MAX_GROWTH = 125
scene.MIN_GROWTH = 65

function scene:createScene(event)
  self.drops = {}
  -- so clicks have something to land on
  self.bg = display.newRect(self.view, screen.xoff, screen.yoff, screen.width, screen.height)
  self.bg:setFillColor(0, 0)
  self.view:insert(self.bg)
  self.spare_drops = {}
  self.last_hue = nil
  for i = 1, scene.DROPS do
    local d = display.newGroup()
    d.subdrops = {}
    d.outer = display.newGroup()
    d:insert(d.outer)
    d.outer.alpha = 0.7
    d.inner = display.newGroup()
    d:insert(d.inner)
    d.inner.alpha = 1
    d.hue = i
    for j = 1, scene.DROP_DEPTH do
      local c = display.newCircle(d, 0, 0, 60)
      c:setFillColor(0)
      c.strokeWidth = j * 2
      c.alpha = 0.1
      c:setStrokeColor(unpack(Rainbow.color(i - 1)))
      c.blendMode = 'add'
      d.outer:insert(c)
    end
    for j = 1, scene.DROP_DEPTH do
      local c = display.newCircle(d, 0, 0, 40)
      c:setFillColor(0, 0)
      c.strokeWidth = j * 1.5
      c.alpha = 0.1
      c:setStrokeColor(unpack(Rainbow.color(i - 1)))
      c.blendMode = 'add'
      d.inner:insert(c)
    end
    table.insert(self.spare_drops, d)
    self.view:insert(d)
    d.isVisible = false
  end
end

function scene:do_drops()
  local spares = {}
  for i, d in ipairs(self.drops) do
    d.xScale = d.xScale + 0.015
    d.yScale = d.yScale + 0.015
    d.outer.xScale = d.outer.xScale + 0.005
    d.outer.yScale = d.outer.yScale + 0.005
    d.inner.xScale = d.inner.xScale + 0.01
    d.inner.yScale = d.inner.yScale + 0.01
    d.growth = d.growth + 1
    if d.growth >= d.max_growth then
      d.isVisible = 0
      d.alpha = 0
      table.insert(spares, i)
    elseif d.growth >= d.max_growth / 2 then
      d.alpha = 1 - ((d.growth - d.max_growth / 2) / (d.max_growth / 2))
    else
      d.alpha = 1
    end
  end
  while #spares > 0 do
    local idx = table.remove(spares)
    table.insert(self.spare_drops, table.remove(self.drops, idx))
  end
  if #self.spare_drops > 0 and math.random(#self.spare_drops) > 12 and self.cooldown < 1 then
    self.cooldown = 10
    local d = table.remove(self.spare_drops, 1)
    if #self.spare_drops > 1 then
      local counter = #self.spare_drops
      while counter > 0 and d.hue == self.last_hue do
        table.insert(self.spare_drops, d)
	d = table.remove(self.spare_drops, 1)
	counter = counter - 1
      end
    end
    self.last_hue = d.hue
    Sounds.play(d.hue)
    d.isVisible = true
    d.x = math.random((screen.width - 50) + 25) + screen.xoff
    d.y = math.random((screen.height - 50) + 25) + screen.yoff
    local range = scene.MAX_GROWTH - scene.MIN_GROWTH
    local scale = math.random(range)
    d.max_growth = scale + scene.MIN_GROWTH
    d.factor = (scale / range) * 0.3
    d.xScale = 0.3 + d.factor
    d.yScale = 0.3 + d.factor
    d.growth = 0
    d.outer.xScale = 1
    d.outer.yScale = 1
    d.inner.xScale = .3
    d.inner.yScale = .3
    table.insert(self.drops, d)
  end
  self.cooldown = self.cooldown - 1
end

function scene:enterFrame(event)
  if self.view.alpha < 1 then
    self.view.alpha = math.min(self.view.alpha + .03, 1)
  end
  self:do_drops()
end

function scene:willEnterScene(event)
  self.view.alpha = 0
end

function scene:enterScene(event)
  self.cooldown = 0
  Runtime:addEventListener('enterFrame', scene)
  self.view:addEventListener('touch', next_display)
end

function scene:didExitScene(event)
  local move_these = {}
  for i, d in ipairs(self.drops) do
    d.alpha = 0
    table.insert(move_these, i)
  end
  while #move_these > 0 do
    table.insert(self.spare_drops, table.remove(self.drops, table.remove(move_these)))
  end
  self.view.alpha = 0
end

function scene:exitScene(event)
  self.view:removeEventListener('touch', next_display)
  Runtime:removeEventListener('enterFrame', scene)
end

function scene:destroyScene(event)
  self.drops = nil
  self.spare_drops = nil
  self.bg = nil
end

scene:addEventListener('createScene', scene)
scene:addEventListener('willEnterScene', scene)
scene:addEventListener('enterScene', scene)
scene:addEventListener('didExitScene', scene)
scene:addEventListener('exitScene', scene)
scene:addEventListener('destroyScene', scene)

return scene
