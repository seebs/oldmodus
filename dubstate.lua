local storyboard = require('storyboard')
local scene = storyboard.newScene()

-- from messing with a rainbow background
scene.COLOR_MULTIPLIER = 50
scene.color_total = #Rainbow.hues * scene.COLOR_MULTIPLIER
scene.DROPS = #Rainbow.hues * 2
scene.MAX_GROWTH = 125
scene.MIN_GROWTH = 45

scene.drums = {
  kick = {
    tone = 1,
    volume = .7,
    effect = {
      hue = 1,
      type = 'circle',
      x = 200, 
      y = 200,
      start = 40,
      finish = 200,
      frames = 30
    } 
  },
  snare = {
    tone = 8,
    volume = .7,
    effect = {
      hue = 5,
      type = 'circle',
      x = 200, 
      y = 700,
      start = 40,
      finish = 200,
      frames = 30
    }
  },
  hat = {
    tone = 25,
    volume = .5,
    effect = {
      hue = 2,
      type = 'circle',
      x = 450,
      y = 500,
      start = 20,
      finish = 100,
      frames = 30,
    }
  }
}

scene.patterns = {
  {
    { type = 'kick', volume = 1, time = 30 },
    { type = 'snare', volume = 1, time = 30 },
    { type = 'kick', volume = 1, time = 15 },
    { type = 'kick', volume = 1, time = 15 },
    { type = 'snare', volume = 1, time = 30 },
  },
  {
    { type = 'hat', volume = 1, time = 10 },
    { type = 'hat', volume = .5, time = 10 },
    { type = 'hat', volume = .5, time = 10 },
  }
}

function scene.setDropVisible(drop, hidden)
  drop.innerc.isVisible = hidden
  drop.innerh.isVisible = hidden
  drop.outerc.isVisible = hidden
  drop.outerh.isVisible = hidden
end

function scene.setDropScale(drop, reset_or_main, inner, outer)
  inner = inner or 1
  outer = outer or 1
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
    drop.innerh.alpha = 1
    drop.outerc.alpha = .8
    drop.outerh.alpha = .8
  else
    drop.innerc.alpha = reset_or_main * inner
    drop.innerh.alpha = reset_or_main * inner
    drop.outerc.alpha = reset_or_main * outer * .8
    drop.outerh.alpha = reset_or_main * outer * .8
  end
end

function scene.setDropColor(drop, color)
  local r, g, b = unpack(Rainbow.color(color))
  drop.innerc:setFillColor(r, g, b)
  drop.outerc:setFillColor(r, g, b)
end

function scene:createScene(event)
  self.drops = {}
  -- so clicks have something to land on
  self.bg = display.newRect(self.view, screen.xoff, screen.yoff, screen.width, screen.height)
  self.bg:setFillColor(0, 0)
  scene.last_color = 1
  self.view:insert(self.bg)
  self.spare_drops = {}
  self.last_hue = nil
  self.sheetc = graphics.newImageSheet("drop_widec.png", { width = 512, height = 512, numFrames = 1 })
  self.sheeth = graphics.newImageSheet("drop_wideh.png", { width = 512, height = 512, numFrames = 1 })
  self.iscale = 2 / 512
  self.oscale = 3 / 512
  for i = 1, scene.DROPS do
    local d = {
      iscale = self.iscale,
      oscale = self.oscale,
      setVisible = self.setDropVisible,
      setScale = self.setDropScale,
      setAlpha = self.setDropAlpha,
      setXY = self.setDropXY,
      setColor = self.setDropColor,
    }
    local img
    d.hue = i
    d.id = i

    img = display.newImage(self.sheetc, 1)
    img.blendMode = 'add'
    self.view:insert(img)
    d.innerc = img

    img = display.newImage(self.sheeth, 1)
    img.blendMode = 'add'
    self.view:insert(img)
    d.innerh = img

    img = display.newImage(self.sheetc, 1)
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
    local mod = (d.finish - d.start) / d.frames
    d:setScale(d.scale + mod, nil, nil)
    d.frame = d.frame + 1
    local halfway = d.frames / 2
    if d.frame >= d.frames then
      d:setVisible(false)
      table.insert(spares, i)
    elseif d.frame >= halfway then
      local mod = 1 - ((d.frame - halfway) / halfway)
      local sqmod = math.sqrt(mod)
      d:setAlpha(mod, sqmod, sqmod)
    else
      d:setAlpha(true)
    end
  end
  while #spares > 0 do
    local drop = table.remove(self.drops, table.remove(spares))
    table.insert(self.spare_drops, drop)
  end
end

function scene:enterFrame(event)
  if self.view.alpha < 1 then
    self.view.alpha = math.min(self.view.alpha + .03, 1)
  end
  self:do_drops()
  local old = #self.drops
  for i, c in ipairs(self.pattern_cooldowns) do
    local pattern = self.patterns[i]
    local state = self.pattern_states[i]
    self.pattern_cooldowns[i] = self.pattern_cooldowns[i] - 1
    if self.pattern_cooldowns[i] < 1 then
      state = (state % #pattern) + 1
      self.pattern_states[i] = state
      local event = pattern[state]
      if event then
	self.pattern_cooldowns[i] = event.time
	local drum = self.drums[event.type]
	Sounds.playexact(drum.tone, drum.volume * (event.volume or 1))
	local effect = drum.effect
	if effect then
	  local drop = table.remove(self.spare_drops, 1)
	  if drop then
	    drop:setColor(effect.hue)
	    drop:setXY(effect.x, effect.y)
	    drop:setAlpha(true)
	    drop:setScale(true)
	    drop:setScale(effect.start)
	    drop.start = effect.start
	    drop.finish = effect.finish
	    drop.frames = effect.frames
	    drop.frame = 1
	    drop:setVisible(true)
	    table.insert(self.drops, drop)
	  else
	    Util.printf("No drop available!")
	  end
	end
      end
    end
  end
  Util.printf("%d/%d drops added", #self.drops - old, #self.drops)
end

function scene:touch_magic(state, ...)
  self.toward = state.ordered[1] and state.ordered[1].current
  return true
end

function scene:willEnterScene(event)
  self.view.alpha = 0
  self.toward = nil
  self.pattern_states = {}
  self.pattern_cooldowns = {}
  for i, p in ipairs(self.patterns) do
    self.pattern_states[i] = 0
    self.pattern_cooldowns[i] = 0
  end
end

function scene:enterScene(event)
  self.cooldown = 0
  Runtime:addEventListener('enterFrame', scene)
  self.view:addEventListener('touch', Touch.handler(self.touch_magic, self))
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
  self.view:removeEventListener('touch', Touch.handler(self.touch_magic, self))
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
