storyboard = require "storyboard"
widget = require "widget"
widget.setTheme("theme_ios")

display.setStatusBar(display.HiddenStatusBar)
system.setIdleTimer(false)

-- profiler = require "Profiler"
-- profiler.startProfiler({time = 30000, delay = 2000, verbose = true })

-- Overall stuff I want to use:
Modus = {}

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

-- debugging and saving memory and things
storyboard.purgeOnSceneChange = true

local displays = {
  'firebugs',
  'fire',
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
  'stringart',
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
-- invisible messages in case any leak out
-- message_box:setTextColor(0, 0, 0, 0)
Util.messages_to(message_box)

system.activate("multitouch")

local touch = Touch
Runtime:addEventListener('touch', function(e) touch:handle(e) end)

if have_settings and scenes.benchmark.settings_complete() then
  Logic.reload_display()
else
  Logic.goto('benchmark')
end
