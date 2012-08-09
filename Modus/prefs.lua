local scene = {}

local frame = Util.enterFrame
local touch = Touch.state

local modus = Modus

local s
local set

function scene:createScene(event)
  s = self.screen
  set = self.settings
  scene.scene_grouping = display.newGroup(s)
  scene.scene_grouping.y = 50
  s:insert(scene.scene_grouping)
  for idx, dname in ipairs(modus.displays) do
    local g = scene:display_one_scene(dname)
    scene.scene_grouping:insert(g)
    g.y = idx * 50
  end
end

function scene:display_one_scene(name)
  local sc = modus.scenes[name]
  if not sc then
    sc = { meta = { name = name, description = "Does not exist." } }
  end
  local g = display.newGroup(scene.scene_grouping)
  local t
  t = display.newText(g, sc.meta.name, 0, 0, native.systemFont, 25)
  g:insert(t)
  t.y = 0
  t = display.newText(g, sc.meta.description, 0, 0, native.systemFont, 15)
  g:insert(t)
  t.y = 26
  return g
end

function scene:touch_magic(state)
  if state.events > 0 then
    reload_display()
  end
end

function scene:destroyScene(event)
  self.scene_grouping = nil
end

return scene
