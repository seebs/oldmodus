local storyboard = require('storyboard')
local scene = storyboard.newScene()

scene.bar_total = #Rainbow.hues + 4
scene.BAR_SPEED = 2
scene.BELL_SPEED = 3

function scene:createScene(event)
  self.bars = {}
  self.recent_hues = {}
  self.bar_height = math.ceil(screen.height / scene.bar_total)
  self.base_cooldown = (self.bar_height / self.BAR_SPEED) / self.BELL_SPEED + 2
  for i = 1, #Rainbow.hues * 2 do
    local r = display.newRect(self.view, screen.xoff, screen.yoff + self.bar_height * #self.bars, screen.width, self.bar_height)
    table.insert(self.bars, r)
    self.view:insert(r)
    r.isVisible = false
  end
  self.rect_top = display.newRect(self.view, screen.xoff, screen.yoff, screen.width, screen.height / 4)
  self.rect_bottom = display.newRect(self.view, screen.xoff, screen.yoff + screen.height * 3 / 4, screen.width, screen.height / 4)
  self.rect_left = display.newRect(self.view, screen.xoff, screen.yoff, screen.width / 4, screen.height)
  self.rect_right = display.newRect(self.view, screen.xoff + screen.width * 3 / 4, screen.yoff, screen.width / 4, screen.height)
  self.grad_top = graphics.newGradient({ 0, 180 }, { 0, 0 }, "down")
  self.grad_bottom = graphics.newGradient({ 0, 180 }, { 0, 0 }, "up")
  self.grad_left = graphics.newGradient({ 0, 180 }, { 0, 0 }, "left")
  self.grad_right = graphics.newGradient({ 0, 180 }, { 0, 0 }, "right")
  self.rect_top:setFillColor(self.grad_top)
  self.rect_bottom:setFillColor(self.grad_bottom)
  self.rect_left:setFillColor(self.grad_left)
  self.rect_right:setFillColor(self.grad_right)
  self.view:insert(self.rect_top)
  self.view:insert(self.rect_bottom)
  self.view:insert(self.rect_left)
  self.view:insert(self.rect_right)
  self.view.alpha = 0
end

function scene:colorBars()
  self.recent_hues = { 0, 0, 0, 0, 0, 0 }
  for i, v in ipairs(self.bars) do
    v.hue = (i % 6) + 1
    v:setFillColor(unpack(Rainbow.color(v.hue)))
    v.isVisible = true
  end
  self.last_hue = 1
end

function scene:too_soon(hue)
  local minimum = 10
  if self.last_hue == hue or self.recent_hues[hue] >= 2 then
    return true
  end
  self.recent_hues[hue] = self.recent_hues[hue] + 1
  for i, v in ipairs(self.recent_hues) do
    minimum = math.min(minimum, v)
  end
  if minimum > 0 then
    for idx, value in ipairs(self.recent_hues) do
      self.recent_hues[idx] = value - minimum
    end
  end
  return false
end

function scene:moveBars()
  self.cooldown = self.cooldown - 1
  if self.cooldown < 0 then
    self.bells = self.bells + 1
    Sounds.play(self.last_hue + self.bells)
    self.cooldown = self.base_cooldown
  end
  for i, v in ipairs(self.bars) do
    v.y = v.y - self.BAR_SPEED
  end
  if self.bars[1].y < screen.yoff + (-1 * self.bar_height) then
    local bar = table.remove(self.bars, 1)
    bar.y = self.bars[#self.bars].y + self.bar_height
    local hue = math.random(6)
    local too_soon = self:too_soon(hue)
    while too_soon do
      hue = math.random(6)
      too_soon = self:too_soon(hue)
    end
    if self.cooldown > 5 then
      Sounds.play(hue)
    end
    self.last_hue = hue
    bar:setFillColor(unpack(Rainbow.color(hue)))
    table.insert(self.bars, bar)
    self.cooldown = self.base_cooldown
    self.bells = 0
  end
end

function scene:enterFrame(event)
  if self.view.alpha < 1 then
    self.view.alpha = math.min(self.view.alpha + .01, 1)
  end
  self:moveBars()
end

function scene:willEnterScene(event)
  self.cooldown = self.base_cooldown
  self.bells = 0
  self:colorBars()
  self:moveBars()
  self.view.alpha = 0
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
  self.bars = {}
  self.top_rect = nil
  self.bottom_rect = nil
  self.left_rect = nil
  self.right_rect = nil
end

scene:addEventListener('createScene', scene)
scene:addEventListener('willEnterScene', scene)
scene:addEventListener('enterScene', scene)
scene:addEventListener('didExitScene', scene)
scene:addEventListener('exitScene', scene)
scene:addEventListener('destroyScene', scene)

return scene
