local scene = {}

local frame = Util.enterFrame
local touch = Touch.state

local s
local set

function scene:createScene(event)
  s = self.screen
  set = self.settings

  self.ids = self.ids or {}
  self.sorted_ids = self.sorted_ids or {}
  self.toward = self.toward or {}

  self.lines = {}
  -- so clicks have something to land on
  self.bg = display.newRect(s, 0, 0, s.size.x, s.size.y)
  self.bg:setFillColor(50, 0, 0)
  self.view:insert(self.bg)
end

function scene:touch_magic(state)
  if state.events > 0 then
    next_display()
  end
end

function scene:destroyScene(event)
  self.bg = nil
end

return scene
