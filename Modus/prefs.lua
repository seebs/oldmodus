local scene = {}

scene.ROW_HEIGHT = 150
scene.NAME_OFFSET = 290
scene.GLOBAL_SPACE = 200

local frame = Util.enterFrame
local touch = Touch.state
local version = require('version_number')

local modus = Modus

local s
local set
local store = require('store')

local store_state = false
local store_product_state = false

local store_product_keys = {
  "thanks",
  "manythanks",
}

local store_products = {}

local function store_callback(event)
  local transaction = event.transaction
  if transaction.state == "purchased" then
    Util.printf("transaction win: %s", transaction.state)
    if scene.store_message_text then
      scene.store_message_text.text = "(Thank you, too!)"
    end
  elseif transaction.state == "restored" then
    Util.printf("transaction replay: %s", transaction.state)
    if scene.store_message_text then
      scene.store_message_text.text = "(You've already thanked me.)"
    end
  elseif transaction.state == "failed" then
    Util.printf("transaction lose: %s, %s", transaction.errorType, transaction.errorString)
    if scene.store_message_text then
      scene.store_message_text.text = "(Transaction failed.)"
    end
  elseif transaction.state == "cancelled" then
    if scene.store_message_text then
      scene.store_message_text.text = "(Transaction cancelled.)"
    end
  else
    Util.printf("transaction WTF: %s", transaction.state)
  end
  store.finishTransaction(transaction)
end

local function store_purchase(item)
  local prod = store_products[item]
  if not prod then
    Util.printf("Can't purchase <%s> because I can't find it.", item)
    return
  end
  store.purchase( { prod } )
end

local function store_product_callback(event)
  local products = event.products
  for idx, prod in ipairs(event.products) do
    if prod.title then
      store_products[prod.productIdentifier] = prod
    end
    Util.printf("%s [%s]: %s", prod.title, prod.productIdentifier, prod.description)
    store_product_state = true
  end
  -- if we were waiting on this before trying to do stuff:
  if store_pending then
    store_purchase(store_pending)
    store_pending = nil
  end
end

local function store_setup()
  if not store_state then
    store.init(store_callback)
    store_state = true
  end
  if not store_product_state then
    store.loadProducts(store_product_keys, store_product_callback)
    return false
  end
  return true
end

function scene.try_to_buy(event, product)
  if event.phase ~= 'release' and event.phase ~= 'tap' then
    return true
  end
  -- might not be ready...
  if not store_setup() then
    store_pending = product
  else
    store_purchase(product)
  end
  return true
end

function scene.thanks_some(event)
  return scene.try_to_buy(event, 'thanks')
end

function scene.thanks_lots(event)
  return scene.try_to_buy(event, 'manythanks')
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

function scene.pick_sound(event)
  if event.phase ~= 'release' and event.phase ~= 'tap' then
    return true
  end
  local button = event.target
  local sound_name = button.id
  Util.printf("picked: %s", sound_name)
  Settings.default_overrides.timbre = sound_name
  Settings.save()
  scene.make_sound_buttons()
  -- and reload sounds if needed
  Sounds.update()
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
  text = display.newText(sc.meta.name, 5, 5, native.systemFont, 30)
  row_group:insert(text)
  row_group.title_label = text
  if not enabled then
    text:setTextColor(180)
  end
  text = display.newText(sc.meta.description, scene.NAME_OFFSET, 10, s.size.x - scene.NAME_OFFSET - 5, scene.ROW_HEIGHT - 10, native.systemFont, 26)
  row_group:insert(text)
  text = display.newText(settings.enabled and "Enabled" or "Disabled", 5, 37, native.systemFont, 26)
  row_group:insert(text)
  if not enabled then
    text:setTextColor(180)
  end
  row_group.enabled_label = text
  local button = widget.newButton({
    id = row.id,
    left = 5,
    top = 110,
    width = 100,
    height = 35,
    label = settings.enabled and "Disable" or "Enable",
    onEvent = scene.toggle_scene,
  })
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

function scene:createScene(event)
  s = self.screen
  set = self.settings
  self.scene_displays = {}
  local row_color

  -- turn on the store
  store_setup()

  scene.scene_list = widget.newTableView({
    hideBackground = true,
    width = s.size.x,
    height = s.size.y,
    topPadding = scene.GLOBAL_SPACE,
    listener = self
  })
  s:insert(scene.scene_list)
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
    top = 10 - scene.GLOBAL_SPACE,
    width = 215,
    height = 38,
    label = "Rerun Benchmarks",
    onEvent = function(event)
      if event.phase == "release" then
        Logic.next_frame_go_to('benchmark')
      end
    end
  })
  scene.scene_list:insert(button)
  button = widget.newButton({
    left = s.size.x - 225,
    top = 10 - scene.GLOBAL_SPACE,
    width = 215,
    height = 38,
    label = "Resume",
    labelColor = {
      default = { 0, 128, 0, 255 },
      over = { 0, 128, 0, 255 }
    },
    onEvent = Modus.reload_display
  })
  scene.scene_list:insert(button)
  local text
  text = display.newText("Global Settings:", 5, 0 - scene.GLOBAL_SPACE, native.systemFont, 40)
  scene.scene_list:insert(text)
  text = display.newText("Sounds:", 5, 52 - scene.GLOBAL_SPACE, native.systemFont, 30)
  scene.scene_list:insert(text)
  scene.make_sound_buttons()

  -- allow IAP
  store_setup()
  if store.canMakePurchases then
    text = display.newText("Thank the app author (IAP, costs money):", 5, 102 - scene.GLOBAL_SPACE, native.systemFont, 23)
    scene.scene_list:insert(text)
    button = widget.newButton({
      left = s.size.x - 290,
      top = 99 - scene.GLOBAL_SPACE,
      width = 110,
      height = 33,
      label = "Thanks!",
      labelColor = {
        default = { 0, 128, 0, 255 },
        over = { 0, 128, 0, 255 }
      },
      onEvent = self.thanks_some
    })
    scene.scene_list:insert(button)
    button = widget.newButton({
      left = s.size.x - 175,
      top = 99 - scene.GLOBAL_SPACE,
      width = 165,
      height = 33,
      label = "Many Thanks!",
      labelColor = {
        default = { 0, 128, 0, 255 },
        over = { 0, 128, 0, 255 }
      },
      onEvent = self.thanks_lots
    })
    scene.scene_list:insert(button)
    scene.store_message_text = display.newText("", 125, 140 - scene.GLOBAL_SPACE, native.systemFont, 23)
    scene.scene_list:insert(scene.store_message_text)
  end
  text = display.newText("Scene Settings:", 5, -45, native.systemFont, 36)
  scene.scene_list:insert(text)
  text = display.newText(version, s.size.x - 50, -25, native.systemFont, 18)
  scene.scene_list:insert(text)
end

function scene.make_sound_buttons()
  local using = Settings.default_overrides.timbre or Settings.default.timbre
  Util.printf("make_sound_buttons: using %s", tostring(using))
  local sounds, descriptions = Sounds.list()
  local left = 125
  local top = 55 - scene.GLOBAL_SPACE
  -- recreate buttons
  if scene.soundbuttons then
    for idx, button in ipairs(scene.soundbuttons) do
      button:removeSelf()
    end
  end
  scene.soundbuttons = {}
  local offset = 0
  for idx, name in ipairs(sounds) do
    -- we force Off to be the leftmost sound
    if name == 'off' then
      offset = -1
    else
      local selected = (name == using)
      button = widget.newButton({
	id = name,
	left = left + ((idx + offset) * 155),
	top = top,
	width = 150,
	labelColor = {
	  default = { 0, selected and 128 or 0, 0, 255 },
	  over = { 0, selected and 0 or 255, 0, 255 }
	},
	height = 33,
	label = descriptions[name],
	onEvent = scene.pick_sound,
      })
      scene.scene_list:insert(button)
    end
  end
  local selected = ('off' == using)
  button = widget.newButton({
    id = 'off',
    left = left,
    top = top,
    labelColor = {
      default = { 0, selected and 128 or 0, 0, 255 },
      over = { 0, selected and 0 or 255, 0, 255 }
    },
    width = 150,
    height = 33,
    label = 'Off',
    onEvent = scene.pick_sound,
  })
  scene.scene_list:insert(button)
end

function scene:touch_magic(state)
  --if state.events > 0 then
  --  Modus.reload_display()
  --end
end

function scene:destroyScene(event)
  Util.printf("prefs: destroying scene.")
  scene.soundbuttons = nil
  scene.store_message_text = nil
  scene.scene_list = nil
end

return scene
