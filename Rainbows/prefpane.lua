local storyboard = require('storyboard')
local scene = storyboard.newScene()

local frame = Util.enterFrame
local touch = Touch.state

local s

function scene:createScene(event)
  self.ids = self.ids or {}
  self.sorted_ids = self.sorted_ids or {}
  self.toward = self.toward or {}

  s = Screen.new(self.view)

  self.lines = {}
  -- so clicks have something to land on
  self.bg = display.newRect(s, 0, 0, s.size.x / 2, s.size.y)
  self.bg:setFillColor(150, 0, 0)
  self.view:insert(self.bg)
end

function scene:enterFrame(event)
  frame()
  touch(self.touch_magic, self)
end

function scene:willEnterScene(event)
end

function scene:enterScene(event)
  touch(nil)
  Runtime:addEventListener('enterFrame', scene)
end

function scene:touch_magic(state, ...)
  storyboard.hideOverlay()
end

function scene:didExitScene(event)
end

function scene:exitScene(event)
  Runtime:removeEventListener('enterFrame', scene)
end

function scene:destroyScene(event)
  self.bg = nil
end

scene:addEventListener('createScene', scene)
scene:addEventListener('willEnterScene', scene)
scene:addEventListener('enterScene', scene)
scene:addEventListener('didExitScene', scene)
scene:addEventListener('exitScene', scene)
scene:addEventListener('destroyScene', scene)

return scene
