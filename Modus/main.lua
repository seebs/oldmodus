local debugging_display = nil
local display_index = 1
local previous_display = 1
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

-- Overall stuff I want to use:
Modus = {}

storyboard = require "storyboard"
widget = require "widget"
widget.setTheme("theme_ios")

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
    if not scenes[name].meta then
      scenes[name].meta = {
        name = name,
	description = "There is no description for this scene."
      }
    end
    Logic:logicize(scenes[name])
    scenes[name].settings = Settings.scene(name)
  end
end

-- pick up any local settings
local have_settings = Settings.load()

-- load sounds now that we know what sounds we like
Sounds.update()

for i, v in ipairs(displays) do
  make_scene(v)
end
make_scene('prefs')
make_scene('benchmark')
Modus.displays = displays
Modus.scenes = scenes

-- we always want the option of displaying stuff:
local message_box = display.newText('', Screen.center.x, Screen.center.y, Screen.size.x - 10, 0, native.defaultFont, 35)
Util.messages_to(message_box)

if debugging_display or debugging_performance then
  Logic.debugging_display = debugging_display
  Logic.debugging_performance = debugging_performance
  storyboard.isDebug = true
end

system.activate("multitouch")

function Modus.reload_display(event)
  if debugging_performance then
    storyboard.printMemUsage()
  end
  if not event or event.phase == 'ended' or event.phase == 'release' then
    if not scenes[displays[display_index]].settings.enabled then
      Modus.next_display(event)
    else
      storyboard.gotoScene(displays[display_index], 'fade', 100)
    end
  end
end

function Modus.last_display(event)
  if debugging_performance then
    storyboard.printMemUsage()
  end
  if not event or event.phase == 'ended' or event.phase == 'release' then
    local prev = ((display_index - 2) % #displays) + 1
    storyboard.gotoScene(displays[prev], 'fade', 100)
    display_index = prev
  end
end

function Modus.next_display(event)
  if debugging_display then
    table.insert(displays, display_index + 1, debugging_display)
    debugging_display = nil
  end
  if debugging_performance then
    storyboard.printMemUsage()
  end
  local next_place = nil
  if not event or event.phase == 'ended' or event.phase == 'release' then
    local started_at = display_index
    while not next_place do
      display_index = (display_index % #displays) + 1
      if display_index == started_at then
	next_place = 'prefs'
	Util.message("You do not appear to have any other scenes enabled.  Enable some scenes.")
	break
      end
      next_place = displays[display_index]
      local enabled = scenes[displays[display_index]].settings.enabled
      if not enabled then
	next_place = nil
      end
    end
    storyboard.gotoScene(next_place, 'fade', 100)
  end
end

local touch = Touch
Runtime:addEventListener('touch', function(e) touch:handle(e) end)

if have_settings and scenes.benchmark.settings_complete() then
  Modus.reload_display()
else
  storyboard.gotoScene('benchmark')
end
