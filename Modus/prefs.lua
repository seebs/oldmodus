local scene = {}

scene.ROW_HEIGHT = 120
scene.NAME_OFFSET = 275

local frame = Util.enterFrame
local touch = Touch.state

local modus = Modus

local s
local set

function scene:beganScroll()
end

function scene:endedScroll()
end

function scene:movingToTopLimit()
end

function scene:movingToBottomLimit()
end

function scene.onRowTouch(event)
  -- row.reRender = true
end

function scene.toggle_scene(event)
  if event.phase ~= 'release' and event.phase ~= 'tap' then
    return true
  end
  local button = event.target
  local scene_name = button.id
  local sc = modus.scenes[scene_name]
  if sc and sc.settings then
    sc.settings.enabled = not sc.settings.enabled
    sc.settings.setting_overrides.enabled = sc.settings.enabled
    Settings.save()
    if sc.settings.enabled then
      button:setLabel("Disable")
      button.parent.title_label:setTextColor(255)
      button.parent.enabled_label:setTextColor(255)
      button.parent.enabled_label.text = "Enabled"
      button.parent.enabled_label:setReferencePoint(display.CenterLeftReferencePoint)
      button.parent.enabled_label.x = 5
    else
      button:setLabel("Enable")
      button.parent.title_label:setTextColor(180)
      button.parent.enabled_label:setTextColor(180)
      button.parent.enabled_label.text = "Disabled"
      button.parent.enabled_label:setReferencePoint(display.CenterLeftReferencePoint)
      button.parent.enabled_label.x = 5
    end
  else
    Util.printf("Got toggle for a scene I can't handle: %s.", tostring(scene_name))
  end
end

function scene.onRowRender(event)
  local row = event.target
  local row_group = event.view
  local sc = modus.scenes[row.id]
  local settings = sc.settings
  local enabled = settings.enabled
  if not sc then
    sc = { meta = { name = row.id or "unnamed", description = "Does not exist." } }
  end
  local text
  text = display.newText(sc.meta.name, 5, 5, native.systemFont, 25)
  row_group:insert(text)
  row_group.title_label = text
  if not enabled then
    text:setTextColor(180)
  end
  text = display.newText(sc.meta.description .. string.format("%.1f", system.getTimer()), scene.NAME_OFFSET, 10, s.size.x - scene.NAME_OFFSET - 5, scene.ROW_HEIGHT - 10, native.systemFont, 20)
  row_group:insert(text)
  text = display.newText(settings.enabled and "Enabled" or "Disabled", 5, 35, native.systemFont, 25)
  row_group:insert(text)
  if not enabled then
    text:setTextColor(180)
  end
  row_group.enabled_label = text
  local button = widget.newButton({
    id = row.id,
    left = 5,
    top = 85,
    width = 100,
    height = 30,
    label = settings.enabled and "Disable" or "Enable",
    onEvent = scene.toggle_scene,
  })
  row_group:insert(button)
end

function scene:display_one_scene(name)
  local sc = modus.scenes[name]
  if not sc then
    sc = { meta = { name = name, description = "Does not exist." } }
  end
  local g = display.newGroup(scene.scene_grouping)
  g.user_height = 100
  local t
  t = display.newText(g, sc.meta.name, 0, 0, native.systemFont, 22)
  t:setReferencePoint(display.topLeftReferencePoint)
  t.x = 0
  t.y = 0
  g:insert(t)
  t = display.newText(g, sc.meta.description, 0, 0, (s.size.x / 2) - 50, 72, native.systemFont, 20)
  t.x = 0
  t.y = 42
  t:setReferencePoint(display.topLeftReferencePoint)
  g:insert(t)
  return g
end

function scene:willEnterScene(event)
  -- I don't want the standard touch events
  Touch.disable()
  -- self.view.alpha = 0
end

function scene:createScene(event)
  s = self.screen
  set = self.settings
  self.scene_displays = {}
  -- reserve some space for global preferences
  base = 250

  scene.scene_list = widget.newTableView({
    hideBackground = true,
    width = s.size.x,
    height = s.size.y,
    topPadding = base,
    listener = self
  })
  s:insert(scene.scene_list)
  for idx, dname in ipairs(modus.displays) do
    line_color = Rainbow.color(idx)
    line_color[4] = 255
    scene.scene_list:insertRow({
      onEvent = scene.onRowTouch,
      onRender = scene.onRowRender,
      height = scene.ROW_HEIGHT,
      id = dname,
      lineColor = line_color,
      rowColor = { 0, 0, 0, 255 }
    })
  end
  local button = widget.newButton({
    left = s.size.x - 220,
    top = (base * -1) + 5,
    width = 215,
    height = 30,
    label = "Rerun Benchmarks",
    onEvent = function(event)
      if event.phase == "release" then
        Logic.next_frame_go_to('benchmark')
      end
    end
  })
  scene.scene_list:insert(button)
  button = widget.newButton({
    left = s.size.x - 220,
    top = (base * -1) + 40,
    width = 215,
    height = 30,
    label = "Resume",
    onEvent = Modus.reload_display
  })
  scene.scene_list:insert(button)
  local text
  text = display.newText("Global Settings:", 5, -base, native.systemFont, 36)
  scene.scene_list:insert(text)
  text = display.newText("Scene Settings:", 5, -45, native.systemFont, 36)
  scene.scene_list:insert(text)
end


function scene:touch_magic(state)
  --if state.events > 0 then
  --  Modus.reload_display()
  --end
end

function scene:destroyScene(event)
  self.scene_grouping = nil
end

return scene
