display.setStatusBar(display.HiddenStatusBar)

player = { slot = 1, score = 0, location = 1 }

--profiler = require "Profiler"
--profiler.startProfiler({time = 20000, delay = 1000, verbose = true})

-- mine get caps so I don't clash
Util = require "Util"
Line = require "Line"
Rainbow = require "Rainbow"
Screen = require "Screen"
Sounds = require "Sounds"
Squares = require "Squares"
Touch = require "Touch"
Vector = require "Vector"

storyboard = require "storyboard"
widget = require "widget"

local displays = {
  'spiral',
  'knights',
  'spline',
  'cascade',
  'drops',
  'spiral2',
  'knights2',
  'lines',
  'cascade2',
  'lissajous',
}
local debugging_display = 'spiral2'
local display_index = 1

local message_box = display.newText('', Screen.center.x, Screen.center.y, native.defaultFont, 50)
Util.messages_to(message_box)

system.activate("multitouch")

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

Runtime:addEventListener('touch', Touch.handle)

next_display()
