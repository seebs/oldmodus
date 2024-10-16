local scene = {}

scene.meta = {
  name = "Preferences",
  description = "Change settings",
}

scene.ROW_HEIGHT = 212
scene.NAME_X_OFFSET = 5
scene.NAME_Y_OFFSET = 202
scene.TEXT_OFFSET = 276
scene.GLOBAL_SPACE = 450

local frame = Util.enterFrame
local touch = Touch.state
local version = require('version_number')

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

function scene.make_buttons(top, tabname, source, include_off, where, what, do_this)
  local using = where[what] or Settings.default[what]
  local items, descriptions = source()
  local left = 125
  local button
  local redo_me = function(...)
    do_this(...)
    scene.make_buttons(top, tabname, source, include_off, where, what, do_this)
  end
  local pick_this_setting = function(event)
    scene.pick_setting(event, where, what, redo_me)
  end
  if scene[tabname] then
    for idx = 1, #scene[tabname] do
      scene[tabname][idx]:removeSelf()
    end
  end
  scene[tabname] = {}
  local offset = include_off and 0 or -1
  for idx = 1, #items do
    name = items[idx]
    local selected = (name == using)
    button = widget.newButton({
	id = name,
	left = left + ((idx + offset) * 160),
	top = top,
	width = 145,
	labelColor = {
	  default = { 0, selected and 128 or 0, 0, 255 },
	  over = { 0, selected and 0 or 255, 0, 255 }
	},
	height = 38,
	label = descriptions[name],
	onEvent = pick_this_setting,
      })
    scene.globals:insert(button)
    scene[tabname][#scene[tabname] + 1] = button
  end
  if include_off then
    button = widget.newButton({
	id = 'off',
	left = left,
	top = top,
	width = 145,
	labelColor = {
	  default = { 0, selected and 128 or 0, 0, 255 },
	  over = { 0, selected and 0 or 255, 0, 255 }
	},
	height = 38,
	label = 'Off',
	onEvent = pick_this_setting,
      })
    scene.globals:insert(button)
    scene[tabname][#scene[tabname] + 1] = button
  end
end

function scene.pick_setting(event, where, what, do_this)
  if event.phase ~= 'release' and event.phase ~= 'tap' then
    return true
  end
  local button = event.target
  local picked = button.id
  where[what] = picked
  Settings.save()
  do_this(picked)
  return true
end

function scene.enable_all(event)
  if event.phase ~= 'release' and event.phase ~= 'tap' then
    return true
  end
  for i, sc in pairs(modus.scenes) do
    sc.settings.enabled = true
    sc.settings.setting_overrides.enabled = sc.settings.enabled
  end
  if scene.scene_list and scene.scene_list.content and scene.scene_list.content.rows then
    for i = 1, #scene.scene_list.content.rows do
      local r = scene.scene_list.content.rows[i]
      scene.update_row_status(r)
    end
  end
  Settings.save()
end

function scene.disable_all(event)
  if event.phase ~= 'release' and event.phase ~= 'tap' then
    return true
  end
  for i, sc in pairs(modus.scenes) do
    sc.settings.enabled = false
    sc.settings.setting_overrides.enabled = sc.settings.enabled
  end
  if scene.scene_list and scene.scene_list.content and scene.scene_list.content.rows then
    for i = 1, #scene.scene_list.content.rows do
      local r = scene.scene_list.content.rows[i]
      scene.update_row_status(r)
    end
  end
  Settings.save()
end

function scene.update_row_status(row)
  local scene_name = row.id
  local sc = modus.scenes[scene_name]
  -- the row may not be rendered yet
  if not row or not row.toggle_button then
    return
  end
  if sc and sc.settings then
    if sc.settings.enabled then
      if row.toggle_button.setReferencePoint then
        row.toggle_button:setLabel("Disable")
      end
      if row.title_label.setTextColor then
        row.title_label:setTextColor(255)
      end
      if row.enabled_label.setTextColor then
        row.enabled_label:setTextColor(255)
      end
      row.enabled_label.text = "Enabled"
      if row.enabled_label.setReferencePoint then
        row.enabled_label:setReferencePoint(display.CenterLeftReferencePoint)
      end
      row.enabled_label.x = scene.TEXT_OFFSET
    else
      if row.toggle_button.setReferencePoint then
        row.toggle_button:setLabel("Enable")
      end
      if row.title_label.setTextColor then
        row.title_label:setTextColor(180)
      end
      if row.enabled_label.setTextColor then
        row.enabled_label:setTextColor(180)
      end
      row.enabled_label.text = "Disabled"
      if row.enabled_label.setReferencePoint then
        row.enabled_label:setReferencePoint(display.CenterLeftReferencePoint)
      end
      row.enabled_label.x = scene.TEXT_OFFSET
    end
  end
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
    scene.update_row_status(button.parent.row)
  else
    -- Util.message("Got toggle for a scene I can't handle: %s.", tostring(scene_name))
  end
end

function scene.onRowRender(event)
  local row = event.target
  local row_group = event.view
  row.view_group = row_group
  row_group.row = row
  local sc = modus.scenes[row.id]
  local settings = sc.settings
  local enabled = settings.enabled
  if not sc then
    sc = { meta = { name = row.id or "unnamed", description = "Does not exist." } }
  end
  local img
  img = display.newImage(row.id .. '.png')
  row_group:insert(img)
  img:setReferencePoint(display.TopLeftReferencePoint)
  img.x = 10
  img.y = 10
  -- img.yScale = 192 / 256;
  -- img.xScale = 192 / 256;
  local text
  text = display.newText(sc.meta.name, scene.TEXT_OFFSET, 5, native.systemFont, 30)
  row_group:insert(text)
  row.title_label = text
  if not enabled then
    text:setTextColor(180)
  end
  text = display.newText(sc.meta.description, scene.TEXT_OFFSET, 80, s.size.x - scene.TEXT_OFFSET - 5, scene.ROW_HEIGHT - 10, native.systemFont, 26)
  row_group:insert(text)
  text = display.newText(settings.enabled and "Enabled" or "Disabled", scene.TEXT_OFFSET, 40, native.systemFont, 26)
  row_group:insert(text)
  if not enabled then
    text:setTextColor(180)
  end
  row.enabled_label = text
  local button = widget.newButton({
    id = row.id,
    left = s.size.x - 110,
    top = 5,
    width = 100,
    height = 35,
    label = settings.enabled and "Disable" or "Enable",
    onEvent = scene.toggle_scene,
  })
  row.toggle_button = button
  row_group:insert(button)
end

function scene:willEnterScene(event)
  -- I don't want the standard touch events
  Touch.disable()
  -- self.view.alpha = 0
end

function scene:enterScene(event)
  Touch.ignore_prefs(true)
  Touch.ignore_doubletaps(true)
  -- in fact, turn off Touch entirely
  Touch.disable()
  display.getCurrentStage():setFocus(nil)
end

function scene.maybe_resume(event)
  if event.phase ~= 'release' and event.phase ~= 'tap' then
    return true
  end
  for i, sc in pairs(modus.scenes) do
    if sc.settings.enabled then
      Logic.reload_display()
      return true
    end
  end
  Util.message("Can't resume when all modes are disabled.")
  Util.message_fade_in(50)
  return true
end

function scene:createScene(event)
  s = self.screen
  set = self.settings
  self.scene_displays = {}
  local row_color

  scene.scene_list = widget.newTableView({
    hideBackground = true,
    width = s.size.x,
    height = s.size.y,
    topPadding = scene.GLOBAL_SPACE,
    listener = self
  })
  s:insert(scene.scene_list)
  scene.globals = display.newGroup()

  for idx, dname in ipairs(modus.displays) do
    row_color = { unpack(Rainbow.color(idx)) }
    row_color[4] = 70
    scene.scene_list:insertRow({
      onEvent = scene.onRowTouch,
      onRender = scene.onRowRender,
      height = scene.ROW_HEIGHT,
      id = dname,
      lineColor = { 0, 0, 0, 255 },
      rowColor = row_color
    })
  end
  local button = widget.newButton({
    left = s.size.x - 450,
    top = 5,
    width = 215,
    height = 42,
    label = "Rerun Benchmarks",
    onEvent = function(event)
      if event.phase == "release" then
        Logic.next_frame_go_to('benchmark')
      end
    end
  })
  scene.globals:insert(button)
  button = widget.newButton({
    left = s.size.x - 225,
    top = 5,
    width = 215,
    height = 42,
    label = "Resume",
    labelColor = {
      default = { 0, 128, 0, 255 },
      over = { 0, 128, 0, 255 }
    },
    onEvent = scene.maybe_resume
  })
  scene.globals:insert(button)
  local text
  text = display.newText("Global Settings:", 5, 0, native.systemFont, 40)
  scene.globals:insert(text)
  text = display.newText("Sounds:", 5, 70, native.systemFont, 30)
  scene.globals:insert(text)
  scene.make_buttons(70, 'soundbuttons', Sounds.list, off, Settings.default_overrides, 'timbre', Sounds.update)
  text = display.newText("Palette:", 5, 120, native.systemFont, 30)
  scene.globals:insert(text)
  scene.make_buttons(125, 'palettebuttons', Rainbow.list, false, Settings.default_overrides, 'palette', function(picked) Rainbow.change_palette(picked) end)
  text = display.newText("Lines:", 5, 170, native.systemFont, 30)
  scene.globals:insert(text)
  local thicknesses = function()
    return { 2, 3, 4 }, { [2] = "Thin", [3] = "Medium", [4] = "Thick" }
  end
  local depths = function()
    return { 1, 2, 4 }, { [1] = "Fast", [2] = "Medium", [4] = "Smooth" }
  end
  scene.make_buttons(175, 'thickbuttons', thicknesses, false, Settings.default_overrides, 'line_thickness', function(picked) end)
  scene.make_buttons(225, 'depthbuttons', depths, false, Settings.default_overrides, 'line_depth', function(picked) end)
  text = display.newText("Modes:", 5, 270, native.systemFont, 30)
  scene.globals:insert(text)
  button = widget.newButton({
    left = 125,
    top = 270,
    width = 145,
    height = 40,
    label = "Enable All",
    labelColor = {
      default = { 0, 128, 0, 255 },
      over = { 0, 128, 0, 255 }
    },
    onEvent = self.enable_all
  })
  scene.globals:insert(button)
  button = widget.newButton({
    left = 285,
    top = 270,
    width = 145,
    height = 40,
    label = "Disable All",
    labelColor = {
      default = { 0, 128, 0, 255 },
      over = { 0, 128, 0, 255 }
    },
    onEvent = self.disable_all
  })
  scene.globals:insert(button)

  text = display.newText("Scene Settings:", 5, scene.GLOBAL_SPACE - 45, native.systemFont, 36)
  scene.globals:insert(text)
  text = display.newText(version, s.size.x - 60, scene.GLOBAL_SPACE - 29, native.systemFont, 22)
  scene.globals:insert(text)

  scene.scene_list:insert(scene.globals)
  scene.globals.y = -scene.GLOBAL_SPACE
end

function scene:touch_magic(state)
  --if state.events > 0 then
  --  Logic.reload_display()
  --end
end

function scene:destroyScene(event)
  -- Util.message("prefs: destroying scene.")
  scene.soundbuttons = nil
  scene.palettebuttons = nil
  scene.thickbuttons = nil
  scene.scene_list = nil
end

return scene
