local scene = {}

scene.meta = {
  name = "Preferences",
  description = "Change settings",
}

-- make this a global so we shouldn't reinitialize it
store_global_state = store_global_state or {
  state = false,
  product_state = false
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
local store = require('store')

local all_store_product_keys = {
  ["Mac OS X"] = {
    "thanks",
    "manythanks",
  },
  ["iPhone OS"] = {
    "thanks",
    "manythanks",
  },
  ["Android"] = {
    "thanks__",
    "manythanks",
  },
}

local store_host = system.getInfo("platformName")

local store_product_keys = all_store_product_keys[store_host] or {}

local store_products = {}

local function store_callback(event)
  local transaction = event.transaction
  -- Util.message("store_callback (%s)", transaction and transaction.state or "nil")
  if transaction.state == "purchased" then
    -- Util.message("transaction win: %s", transaction.state)
    already_bought[transaction.productIdentifier] = true
    scene.store_message("Thank you, too!")
  elseif transaction.state == "restored" then
    -- Util.message("transaction replay: %s", transaction.state)
    scene.store_message("You've already thanked me.")
  elseif transaction.state == "failed" then
    -- Util.message("transaction lose: %s, %s", transaction.errorType, transaction.errorString)
    scene.store_message("Transaction failed.")
  elseif transaction.state == "cancelled" then
    scene.store_message("Transaction cancelled.")
  else
    -- Util.message("transaction WTF: %s", transaction.state)
  end
  store.finishTransaction(transaction)
end

local function store_purchase(item)
  local prod = store_products[item]
  if not prod then
    -- Util.message("Can't purchase <%s> because I can't find it.", item)
    return
  end
  store.purchase( { prod } )
end

local function store_product_callback(event)
  local products = event.products
  -- Util.message("store_product_callback.")
  for idx, prod in ipairs(event.products) do
    if prod.title then
      store_products[prod.productIdentifier] = prod
    end
    -- Util.message("%s [%s]: %s", prod.title, prod.productIdentifier, prod.description)
    store_global_state.product_state = true
    if store_pending then
      store_purchase(store_pending)
      store_pending = nil
    end
  end
  for idx, prod in ipairs(event.invalidProducts) do
    -- Util.message("  invalid: %s", prod)
  end
  -- if we were waiting on this before trying to do stuff:
end

local function store_setup()
  -- Util.message("store.availableStores: %s", table.concat(store.availableStores, ", "))
  if not store_global_state.state then
    -- Util.message("store setup for host %s", store_host)
    store.init(store_callback)
    store_global_state.state = true
  end
  if not store_global_state.product_state then
    if store.canLoadPurchases then
      -- Util.message("trying to get products configured for %s:", store_host)
      for i = 1, #store_product_keys do
        -- Util.message("  %d: %s", i, store_product_keys[i])
      end
      store.loadProducts(store_product_keys, store_product_callback)
      return false
    else
      -- Android doesn't let you query the server like that.
      for i = 1, #store_product_keys do
	local prod = store_product_keys[i]
        store_products[prod] = prod
      end
      store_global_state.product_state = true
      return true
    end
  end
  return true
end

function scene.try_to_buy(event, product)
  -- Util.message("try_to_buy: phase %s, product %s", event.phase, tostring(product))
  if event.phase ~= 'release' and event.phase ~= 'tap' then
    return true
  end
  if not product then
    return true
  end
  if already_bought[product] then
    scene.store_message("You have already thanked me.")
    return true
  end
  -- might not be ready...
  if not store_setup() then
    scene.store_message("Store offline? Retry later.")
  else
    store_purchase(product)
  end
  return true
end

function scene.thanks_some(event)
  return scene.try_to_buy(event, store_product_keys[1])
end

function scene.thanks_lots(event)
  return scene.try_to_buy(event, store_product_keys[2])
end

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

function scene.store_message(fmt, ...)
  local txt = Util.sprintf(fmt, ...)
  if scene.store_message_text then
    scene.store_message_text.text = "(" .. txt .. ")"
    scene.store_message_text:setReferencePoint(display.TopLeftReferencePoint)
    scene.store_message_text.x = 5
    scene.store_message_text.y = scene.GLOBAL_SPACE - 70
  end
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

  -- allow IAP
  scene.store_message_text = display.newText("", 125, scene.GLOBAL_SPACE - 70, native.systemFont, 23)
  scene.globals:insert(scene.store_message_text)
  store_setup()
  if store.canMakePurchases then
    text = display.newText("Thank the app author (costs money):", 5, scene.GLOBAL_SPACE - 110 , native.systemFont, 23)
    scene.globals:insert(text)
    button = widget.newButton({
      left = s.size.x - 330,
      top = scene.GLOBAL_SPACE - 116,
      width = 130,
      height = 40,
      label = "Thanks!",
      labelColor = {
        default = { 0, 128, 0, 255 },
        over = { 0, 128, 0, 255 }
      },
      onEvent = self.thanks_some
    })
    scene.globals:insert(button)
    button = widget.newButton({
      left = s.size.x - 185,
      top = scene.GLOBAL_SPACE - 116,
      width = 175,
      height = 40,
      label = "Many Thanks!",
      labelColor = {
        default = { 0, 128, 0, 255 },
        over = { 0, 128, 0, 255 }
      },
      onEvent = self.thanks_lots
    })
    scene.globals:insert(button)
  else
    scene.store_message("Thanks for trying the Miracle Modus!")
  end
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
  scene.store_message_text = nil
  scene.scene_list = nil
end

return scene
