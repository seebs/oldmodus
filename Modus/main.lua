local debugging_display = nil
local display_index = 1
local debugging_performance = false

display.setStatusBar(display.HiddenStatusBar)

--profiler = require "Profiler"
--profiler.startProfiler({time = 30000, delay = 1000, verbose = true, callback = function() Line.redraws() end })

-- mine get caps so I don't clash
-- stuff everyone else needs
Rainbow = require "Rainbow"
Settings = require "Settings"
Util = require "Util"
Screen = require "Screen"

-- basic interface bits
Sounds = require "Sounds"
Touch = require "Touch"
Logic = require "Logic"

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
  'spiral',
  'ants2',
  'knights',
  'spline',
  'cascade',
  'lissajous',
  'drops',
  'spiral2',
  'ants',
  'cascade2',
  'lines',
  'knights2',
}

local display_code = {}
local scenes = {}

function make_scene(name)
  display_code[name] = require(name)
  if display_code[name] then
    scenes[name] = storyboard.newScene(name)
    scenes[name].name = name
    for key, value in pairs(display_code[name]) do
      scenes[name][key] = value
    end
    Logic:logicize(scenes[name])
  end
end

-- pick up any local settings
local have_settings = Settings.load()

for i, v in ipairs(displays) do
  make_scene(v)
end
make_scene('prefs')
make_scene('benchmark')

if debugging_display or debugging_performance then
  Logic.debugging_display = debugging_display
  Logic.debugging_performance = debugging_performance
  storyboard.isDebug = true
  local message_box = display.newText('', Screen.center.x, Screen.center.y, native.defaultFont, 35)
  Util.messages_to(message_box)
end

system.activate("multitouch")

function reload_display(event)
  if debugging_performance then
    storyboard.printMemUsage()
  end
  if not event or event.phase == 'ended' then
    local prev = ((display_index - 2) % #displays) + 1
    storyboard.gotoScene(displays[prev], 'fade', 500)
  end
end

function last_display(event)
  if debugging_performance then
    storyboard.printMemUsage()
  end
  if not event or event.phase == 'ended' then
    local prev = ((display_index - 3) % #displays) + 1
    storyboard.gotoScene(displays[prev], 'fade', 500)
    display_index = (prev % #displays) + 1
  end
end

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

if have_settings and scenes.benchmark.settings_complete() then
  next_display()
else
  storyboard.gotoScene('benchmark')
end
