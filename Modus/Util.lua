local Util = {}

local pow = math.pow
local atan2 = math.atan2
local min = math.min
local max = math.max
local sqrt = math.sqrt

Util.frame_to_ms = 1000 / (display.fps or 60)
Util.ms_to_frame = (display.fps or 60) / 1000

function Util.scale(o)
  local level = o.level or 1
  return pow(1.1, level)
end

local message_boxes = {}
local message_box

local message_fade_in = 0

function Util.message_fade(amount)
  if not amount then
    if message_fade_in > 0 then
      amount = -0.07
      message_fade_in = message_fade_in - 1
    else
      amount = 0.03
    end
  end
  message_box.alpha = min(max(0, message_box.alpha - amount), 1)
end

function Util.message_fade_in(value)
  message_fade_in = value or 50
  message_box.alpha = 0
end

function Util.message(fmt, ...)
  local out = Util.sprintf(fmt, ...)
  if not message_box then
    message_box = display.newGroup()
    for i = 1, 5 do
      -- specifying a width has unexpected behaviors on Android
      -- message_boxes[i] = display.newText('blah', Screen.center.x, Screen.center.y, Screen.size.x - 10, 0, native.defaultFont, 40)
      message_boxes[i] = display.newText('blah', Screen.center.x, Screen.center.y, native.defaultFont, 40)
    end
    message_boxes[1]:setTextColor(0)
    message_boxes[2]:setTextColor(0)
    message_boxes[3]:setTextColor(0)
    message_boxes[4]:setTextColor(0)
    message_boxes[5]:setTextColor(255)

    message_box:insert(message_boxes[1])
    message_box:insert(message_boxes[2])
    message_box:insert(message_boxes[3])
    message_box:insert(message_boxes[4])
    message_box:insert(message_boxes[5])
  end
  for i = 1, #message_boxes do
    local box = message_boxes[i]
    box.text = out
    box:setReferencePoint(display.centerReferencePoint)
  end
  message_box.x = (Screen.size.x / 2) + Screen.origin.x
  message_box.y = (Screen.size.y / 2) + Screen.origin.y
  message_boxes[1].x = - 1.5
  message_boxes[1].y = - 1.5
  message_boxes[2].x = - 1.5
  message_boxes[2].y =   1.5
  message_boxes[3].x =   1.5
  message_boxes[3].y = - 1.5
  message_boxes[4].x =   1.5
  message_boxes[4].y =   1.5
  message_boxes[5].x = 0
  message_boxes[5].y = 0
  message_box.alpha = 1
  local dir = system.orientation
  if dir == 'portraitUpsideDown' then
    message_box.rotation = 180
  elseif dir == 'landscapeLeft' then
    message_box.rotation = 270
  elseif dir == 'landscapeRight' then
    message_box.rotation = 90
  else
    message_box.rotation = 0
  end
  print(out)
end

function Util.gcd(x, y)
  if x < y then
    return Util.gcd(y, x)
  else
    if y > 0 then
      return Util.gcd(y, x % y)
    else
      return x
    end
  end
end

function Util.line(a, b)
  local dx = b.x - a.x
  local dy = b.y - a.y
  return {
    x = (a.x + b.x) / 2,
    y = (a.y + b.y) / 2,
    len = sqrt(dx * dx + dy * dy),
    theta = atan2(dy, dx) }
end

function Util.vec_add(v1, v2)
  return { x = v1.x + v2.x, y = v1.y + v2.y }
end

function Util.vec_scale(v, s)
  return { x = v.x * s, y = v.y * s }
end

function Util.midpoint(a, b)
  return { x = (a.x + b.x) / 2,
           y = (a.y + b.y) / 2 }
end

function Util.partway(a, b, ratio)
  ratio = ratio or 0.5
  local scale = 1 - ratio
  return { x = a.x * scale + b.x * ratio,
           y = a.y * scale + b.y * ratio }
end

function Util.dist(a, b)
  local dx = a.x - b.x
  local dy = a.y - b.y
  return sqrt(dx * dx + dy * dy)
end

local skip_items = {
  new = true,
}

function Util.weakcopy(dest, source, required_type)
  if not dest or not source then
    return
  end
  for k, v in pairs(source) do
    if not ((required_type and type(v) ~= required_type) or skip_items[k]) then
      if not (source.nocopy and source.nocopy[k]) then
        if dest[k] then
	  if not (source.optional and source.optional[k]) then
            Util.printf("Trying to add %s to an object which already has it.", k)
          end
	else
          dest[k] = v
        end
      end
    end
  end
end

-- prototyping!
function Util.bless(obj, class)
  obj.prototypes = obj.prototypes or {}
  table.insert(obj.prototypes, class)
  Util.weakcopy(obj, class, 'function')
  Util.weakcopy(obj, class.defaults)
end

function Util.move_towards(self, target, y)
  local got_there = true
  local dx, dy, dist
  if not target then
    return
  end
  if y then
    dx = target - self.x
    dy =      y - self.y
  else
    if not target.x or not self.x then
      Util.printf("target.x: %s self.x: %s", tostring(target.x), tostring(self.x))
    end
    dx = target.x - self.x
    dy = target.y - self.y
  end
  local dist = Util.dist(dx, dy)
  local speed = self.speed or 10
  if dist > speed then
    dx = dx * (speed / dist)
    dy = dy * (speed / dist)
    got_there = false
  end
  self.x = self.x + dx
  self.y = self.y + dy
  return got_there
end

function Util.timer_tick(timed, field)
  local removes = {}
  local removed = {}
  field = field or 'time'
  for idx, item in ipairs(timed) do
    if item.tick then
      item:tick()
    end
    if item[field] and type(item[field]) == 'number' then
      item[field] = item[field] - 1
      if item[field] <= 0 then
        table.insert(removes, idx)
      end
    end
  end
  -- remove backwards so renumbering doesn't bite us
  while #removes > 0 do
    local idx = table.remove(removes)
    table.insert(removed, timed[idx])
    table.remove(timed, idx)
  end
  return #removed > 0 and removed
end

function Util.sprintf(fmt, ...)
  local foo = function(...) return string.format(fmt or 'nil', ...) end
  local status, value = pcall(foo, ...)
  if status then
    return value
  else
    return 'Format "' .. (fmt or 'nil') .. '": ' .. value
  end
end

function Util.printf(fmt, ...)
  print(Util.sprintf(fmt, ...))
end

function Util.to_s(v)
  local foo = function() return tostring(v) end
  okay, values = pcall(foo)
  if okay then
    return values
  else
    return '[invalid ' .. type(v) .. ']'
  end
end

function Util.keys(t)
  local kt = {}
  for k, v in pairs(t) do
    table.insert(kt, Util.to_s(k))
  end
  return kt
end

function Util.showkeys(t)
  t = t or _G
  if type(t) ~= 'table' then
    Util.printf("showkeys needs a table.")
    return
  end
  local kt = Util.keys(t)
  table.sort(kt)
  local out = {}
  for _, k in ipairs(kt) do
    table.insert(out, k)
    if #out > 15 then
      print(table.concat(out, ', '))
      out = {}
    end
  end
  if #out > 0 then
    print(table.concat(out, ', '))
  end
end

function Util.print_item(prefix, key, value, t, k, v)
  Util.printf("%s%s: %s", prefix, key, value)
end

function Util.print_if(pattern, prefix, key, value)
  if string.match(value, pattern) then
    Util.printf("%s%s: %s", prefix, key, value)
  end
end

function Util.contains(pattern, depth, t)
  t = t or _G
  local tables = {}
  local keys = {}
  Util.iterate(t, depth, function(p, ks, vs, t, k, v) if string.match(vs, pattern) then table.insert(tables, t); table.insert(keys, k) end end)
  return tables, keys
end

function Util.grep(pattern, depth, t)
  t = t or _G
  Util.iterate(t, depth, function(p, k, v) Util.print_if(pattern, p, k, v) end)
end

function Util.list(t, field)
  t = t or _G
  if type(t) ~= 'table' then
    Util.printf("list needs a table.")
    return
  end
  local kt = {}
  for k, v in pairs(t) do
    table.insert(kt, k)
  end
  local sort_it = function() table.sort(kt) end
  pcall(sort_it)
  local out = {}
  for _, k in ipairs(kt) do
    local v = t[k]
    local listing = nil
    if type(v) == 'table' then
      if field then
	listing = v[field]
      else
	listing = (v.uiName or v.name or v.description) or listing
      end
      if listing then
        Util.printf("%s: [%s] %s", Util.to_s(k), Util.to_s(v), Util.to_s(listing))
      end
    end
  end
end

function Util.iterate(t, maxdepth, callback, prefix, visited)
  if not t or type(t) ~= 'table' then
    Util.printf("That's a %s, not a table.", type(t))
    return
  end
  if maxdepth and maxdepth <= 0 then
    return
  end
  if not callback or type(callback) ~= 'function' then
    callback = Util.print_item
  end
  prefix = prefix or ''
  visited = visited or {}
  visited[t] = true
  local count = 0
  for k, v in pairs(t) do
    local k2 = Util.to_s(k)
    count = count + 1
    callback(prefix, k2, Util.to_s(v), t, k, v)
    if type(v) == 'table' and not visited[v] and (string.sub(k2, 1, 2) ~= '__') then
      Util.iterate(v, maxdepth and (maxdepth - 1), callback, prefix .. Util.to_s(k) .. '.', visited)
    end
  end
  return count
end

function Util.dump(t, depth, prefix)
  local count = Util.iterate(t, depth, print_item, prefix, {})
end

return Util
