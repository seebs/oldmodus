display.setStatusBar(display.HiddenStatusBar)

player = { slot = 1, score = 0, location = 1 }

-- profiler = require "Profiler"
-- profiler.startProfiler({time = 30000, delay = 1000, verbose = true})

-- mine get caps so I don't clash
-- stuff everyone else needs
Settings = require "Settings"
Util = require "Util"
Touch = require "Touch"
Logic = require "Logic"

-- basic interface bits
Rainbow = require "Rainbow"
Screen = require "Screen"
Sounds = require "Sounds"

-- graphics tools
Line = require "Line"
Squares = require "Squares"
Hexes = require "Hexes"
Vector = require "Vector"

storyboard = require "storyboard"
widget = require "widget"

-- debugging and saving memory and things
storyboard.purgeOnSceneChange = true

local displays = {
  'spline',
  'spiral',
  'knights2',
  'knights',
  'spiral2',
}

local notyet = {
  'cascade',
  'drops',
  'ants',
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
