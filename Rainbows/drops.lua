local storyboard = require('storyboard')
local scene = storyboard.newScene()

-- from messing with a rainbow background
scene.COLOR_MULTIPLIER = 50
scene.color_total = #Rainbow.hues * scene.COLOR_MULTIPLIER
scene.DROPS = #Rainbow.hues * 2
scene.MAX_GROWTH = 125
scene.MIN_GROWTH = 45

function scene.setDropVisible(drop, hidden)
  drop.innerc.isVisible = hidden
  drop.innerh.isVisible = hidden
  drop.outerc.isVisible = hidden
  drop.outerh.isVisible = hidden
end

function scene.setDropScale(drop, reset_or_main, inner, outer)
  if reset_or_main == true then
    drop.scale = 1
    drop.inner_scale = 1
    drop.outer_scale = 1
    drop.innerc:scale(drop.iscale, drop.iscale)
    drop.innerh:scale(drop.iscale, drop.iscale)
    drop.outerc:scale(drop.oscale, drop.oscale)
    drop.outerh:scale(drop.oscale, drop.oscale)
  else
    local is = drop.iscale * inner * reset_or_main
    local os = drop.iscale * outer * reset_or_main
    drop.scale = reset_or_main
    drop.inner_scale = inner
    drop.outer_scale = outer
    drop.innerc.xScale = is
    drop.innerc.yScale = is
    drop.innerh.xScale = is
    drop.innerh.yScale = is
    drop.outerc.xScale = os
    drop.outerc.yScale = os
    drop.outerh.xScale = os
    drop.outerh.yScale = os
  end
end

function scene.setDropXY(drop, x, y)
  drop.x = x
  drop.y = y
  drop.innerc.x, drop.innerc.y = x, y
  drop.innerh.x, drop.innerh.y = x, y
  drop.outerc.x, drop.outerc.y = x, y
  drop.outerh.x, drop.outerh.y = x, y
end

function scene.setDropAlpha(drop, reset_or_main, inner, outer)
  if reset_or_main == true then
    drop.innerc.alpha = 1
    drop.innerh.alpha = .8
    drop.outerc.alpha = .8
    drop.outerh.alpha = .64
  else
    drop.innerc.alpha = reset_or_main * inner
    drop.innerh.alpha = reset_or_main * inner * .8
    drop.outerc.alpha = reset_or_main * outer * .8
    drop.outerh.alpha = reset_or_main * outer * .64
  end
end

local s

function scene:createScene(event)
  self.drops = {}
  s = Screen.new(self.view)
  -- so clicks have something to land on
  self.bg = display.newRect(s, 0, 0, s.size.x, s.size.y)
  self.bg:setFillColor(0, 0)
  scene.last_color = 1
  s:insert(self.bg)
  self.spare_drops = {}
  self.last_hue = nil
  self.sheetc = graphics.newImageSheet("drop_widec.png", { width = 512, height = 512, numFrames = 1 })
  self.sheeth = graphics.newImageSheet("drop_wideh.png", { width = 512, height = 512, numFrames = 1 })
  self.iscale = 200 / 512
  self.oscale = 300 / 512
  for i = 1, scene.DROPS do
    local d = {
      iscale = self.iscale,
      oscale = self.oscale,
      setVisible = self.setDropVisible,
      setScale = self.setDropScale,
      setAlpha = self.setDropAlpha,
      setXY = self.setDropXY,
    }
    local img
    d.hue = i
    d.id = i
    local r, g, b = unpack(Rainbow.color(i - 1))

    img = display.newImage(self.sheetc, 1)
    img:setFillColor(r, g, b)
    img.blendMode = 'add'
    self.view:insert(img)
    d.innerc = img

    img = display.newImage(self.sheeth, 1)
    img.blendMode = 'add'
    self.view:insert(img)
    d.innerh = img

    img = display.newImage(self.sheetc, 1)
    img:setFillColor(r, g, b, 180)
    img.blendMode = 'add'
    self.view:insert(img)
    d.outerc = img

    img = display.newImage(self.sheeth, 1)
    img.blendMode = 'add'
    img:setFillColor(255, 180)
    self.view:insert(img)
    d.outerh = img

    d:setScale(true)
    d:setAlpha(true)
    d:setVisible(false)

    table.insert(self.spare_drops, d)
  end
end

function scene:do_drops()
  local spares = {}
  for i, d in ipairs(self.drops) do
    d:setScale(d.scale + 0.01, d.inner_scale + 0.01, d.outer_scale + 0.01)
    d.growth = d.growth + 1
    local halfway = d.max_growth / 2
    if d.growth >= d.max_growth then
      d:setVisible(false)
      table.insert(spares, i)
    elseif d.growth >= halfway then
      local mod = 1 - ((d.growth - halfway) / halfway)
      local sqmod = math.sqrt(mod)
      d:setAlpha(mod, sqmod, sqmod)
    else
      d:setAlpha(true)
    end
  end
  while #spares > 0 do
    local idx = table.remove(spares)
    table.insert(self.spare_drops, table.remove(self.drops, idx))
  end
  if #self.spare_drops > 0 and math.random(#self.spare_drops) > 6 and self.cooldown < 1 then
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
    local new_point = {}
    new_point.x = math.random((s.size.x - 50) + 25)
    new_point.y = math.random((s.size.y - 50) + 25)
    if self.toward then
      local between = Util.between(new_point, self.toward)
    end
    d:setXY(new_point.x, new_point.y)
    local range = scene.MAX_GROWTH - scene.MIN_GROWTH
    local scale = math.random(range)
    d.max_growth = scale + scene.MIN_GROWTH
    d.factor = (scale / range) * 0.3
    d:setVisible(true)
    d:setAlpha(true)
    d:setScale(0.1 + d.factor, .3, 1)
    d.growth = 0
    table.insert(self.drops, d)
  end
  self.cooldown = self.cooldown - 1
end

function scene:enterFrame(event)
  Util.enterFrame()
  if self.view.alpha < 1 then
    self.view.alpha = math.min(self.view.alpha + .03, 1)
  end
  self:do_drops()
end

function scene:touch_magic(state, ...)
  self.toward = state.ordered[1] and state.ordered[1].current
  return true
end

function scene:willEnterScene(event)
  self.view.alpha = 0
  self.toward = nil
end

function scene:enterScene(event)
  self.cooldown = 0
  Runtime:addEventListener('enterFrame', scene)
  Touch.handler(self.touch_magic, self)
end

function scene:didExitScene(event)
  local move_these = {}
  for i, d in ipairs(self.drops) do
    d:setVisible(false)
    d:setScale(true)
    table.insert(move_these, i)
  end
  while #move_these > 0 do
    table.insert(self.spare_drops, table.remove(self.drops, table.remove(move_these)))
  end
  self.view.alpha = 0
end

function scene:exitScene(event)
  Runtime:removeEventListener('enterFrame', scene)
  Touch.handler()
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
