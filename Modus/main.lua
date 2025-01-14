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
  'spiral1',
  'hexes2',
  'knights1',
  'spline',
  'cascade',
  'lissajous',
  'raindrops',
  'spiral2',
  'fire',
  'hexes1',
  'cascade2',
  'lines',
  'knights2',
  'stringart',
  'firebugs',
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

-- prevent spamming the IAP keys
already_bought = {}

for i, v in ipairs(displays) do
  make_scene(v)
end
make_scene('prefs')
make_scene('benchmark')
Modus.displays = displays
Modus.scenes = scenes

system.activate("multitouch")

local touch = Touch

local function handle_key(event)
  if event and event.keyName == 'menu' then
    Logic.goto('prefs')
    return true
  end
end

Runtime:addEventListener('touch', function(e) touch:handle(e) end)
-- android has hardware key support
if system.getInfo("platformName") == "Android" then 
  Runtime:addEventListener('key', handle_key)
end

if have_settings and scenes.benchmark.settings_complete() then
  Logic.reload_display()
else
  Logic.goto('benchmark')
end
