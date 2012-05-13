display.setStatusBar(display.HiddenStatusBar)

player = { slot = 1, score = 0, location = 1 }

-- profiler = require "Profiler"
-- profiler.startProfiler({time = 30000, delay = 1000, verbose = true})

-- mine get caps so I don't clash
Util = require "Util"
Line = require "Line"
Rainbow = require "Rainbow"
Screen = require "Screen"
Sounds = require "Sounds"
Squares = require "Squares"
Hexes = require "Hexes"
Touch = require "Touch"
Vector = require "Vector"
Settings = require "Settings"
Logic = require "Logic"

storyboard = require "storyboard"
widget = require "widget"

-- debugging and saving memory and things
storyboard.purgeOnSceneChange = true

local displays = {
  'knights',
  'spiral2',
  'spiral',
}

local notyet = {
  'knights',
  'spline',
  'cascade',
  'drops',
  'ants',
  'knights2',
  'lines',
  'cascade2',
  'lissajous',
  'ants2',
}

local display_code = {}
local scenes = {}

for i, v in ipairs(displays) do
  display_code[v] = require(v)
  if display_code[v] then
    scenes[v] = storyboard.newScene(v)
    scenes[v].name = v
    for key, value in pairs(display_code[v]) do
      scenes[v][key] = value
    end
    Logic:logicize(scenes[v])
  end
end

local debugging_display = nil
local display_index = 1
local debugging_performance = true
if debugging_display or debugging_performance then
  storyboard.isDebug = true
  local message_box = display.newText('', Screen.center.x, Screen.center.y, native.defaultFont, 35)
  Util.messages_to(message_box)
end

system.activate("multitouch")

function next_display(event)
  if debugging_display then
    table.insert(displays, display_index, debugging_display)
    debugging_display = nil
  end
  if debugging_performance then
    storyboard.printMemUsage()
  end
  if not event or event.phase == 'ended' then
    storyboard.gotoScene(displays[display_index], 'fade', 500)
    display_index = (display_index % #displays) + 1
  end
end

Runtime:addEventListener('touch', Touch.handle)

next_display()
