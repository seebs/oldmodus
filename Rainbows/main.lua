display.setStatusBar(display.HiddenStatusBar)

player = { slot = 1, score = 0, location = 1 }

storyboard = require "storyboard"
widget = require "widget"

-- mine get caps so I don't clash
Util = require "Util"
Rainbow = require "Rainbow"
Sounds = require "Sounds"

local displays = { 'bars', 'drops', 'knights', 'knights2', 'qix' }
local debugging_display = 'qix'
local display_index = 1

display_offset = { x = display.screenOriginX, y = display.screenOriginY }
screen = {
  x = display.contentWidth,
  y = display.contentHeight,
  width = display.contentWidth - (2 * display.screenOriginX),
  height = display.contentHeight - (2 * display.screenOriginY),
  xoff = display.screenOriginX,
  yoff = display.screenOriginY,
}

screen.left = screen.xoff
screen.top = screen.yoff
screen.right = screen.xoff + screen.width
screen.bottom = screen.yoff + screen.height

function next_display(event)
  if debugging_display then
    table.insert(displays, display_index, debugging_display)
    debugging_display = nil
  end
  if not event or event.phase == 'ended' then
    storyboard.gotoScene(displays[display_index], 'fade', 500)
    display_index = (display_index % #displays) + 1
  end
end

next_display()
