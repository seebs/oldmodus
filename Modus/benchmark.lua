local scene = {}

local frame = Util.enterFrame
local touch = Touch.state

local s
local set

local sprintf = Util.sprintf
local printf = Util.printf
local timer = system.getTimer
local co = coroutine
local to_s = tostring
local floor = math.floor
local ceil = math.ceil

function scene:createScene(event)
  s = self.screen
  set = self.settings
end

function scene:touch_magic(state)
  if state.events > 0 then
    Modus.next_display()
  end
end

function scene:state1(fmt, ...)
  if not self.state1text then
    self.state1text = display.newText('', Screen.center.x, Screen.center.y, native.defaultFont, 30)
    s:insert(self.state1text)
  end
  self.state1text.text = sprintf(fmt, ...)
  self.state1text:setReferencePoint(display.TopLeftReferencePoint)
  self.state1text.x = 10
  self.state1text.y = 220
end

function scene:state2(fmt, ...)
  if not self.state2text then
    self.state2text = display.newText('', Screen.center.x, Screen.center.y, native.defaultFont, 30)
    s:insert(self.state2text)
  end
  self.state2text.text = sprintf(fmt, ...)
  self.state2text:setReferencePoint(display.TopLeftReferencePoint)
  self.state2text.x = 10
  self.state2text.y = 260
end

function scene.do_nothing(self, count)
  local j
  while count do
    for i = 1, count do 
      j = to_s(i)
    end
    self, count = co.yield(count)
  end
end

local do_hexes_stash

function scene.do_hexes(self, count)
  local hexsheet = Hexes.sheet
  do_hexes_stash = display.newImageGroup(hexsheet)
  do_hexes_stash.hexes = {}

  local old_count = 0
  while count do
    for i = old_count + 1, count do
      local spot = i - 1
      local x_loc = (spot % 40) * 18 + 10
      local y_loc = floor(spot / 40) * 18 + 275
      local l = display.newImage(hexsheet, 1)
      l.x = x_loc
      l.y = y_loc
      l.xScale = 18 / 256
      l.yScale = 18 / 256
      l:setFillColor(unpack(Rainbow.color(i)))
      l.blendMode = 'add'
      do_hexes_stash.hexes[#do_hexes_stash.hexes + 1] = l
      do_hexes_stash:insert(l)
    end
    old_count = count
    for i = count - ceil(count / 4), count do 
      do_hexes_stash.hexes[i].rotation = (i + count)
    end
    self, count = co.yield(count)
  end
  do_hexes_stash:removeSelf()
  do_hexes_stash = nil
end

local do_rects_stash
local rect_new = display.newRect

function scene.do_rects(self, count)
  do_rects_stash = display.newGroup()
  do_rects_stash.rects = {}
  local old_count = 0
  while count do
    for i = old_count + 1, count do
      local spot = i - 1
      local x_loc = (spot % 40) * 18.5
      local y_loc = floor(spot / 40) * 18 + 300
      local l = rect_new(s, x_loc, y_loc, 18, 18)
      l:setFillColor(unpack(Rainbow.color(i)))
      l.alpha = 0.8
      l.blendMode = 'add'
      do_rects_stash.rects[#do_rects_stash.rects + 1] = l
      do_rects_stash:insert(l)
    end
    old_count = count
    for i = count - ceil(count / 4), count do 
      do_rects_stash.rects[i].rotation = (i + count)
    end
    self, count = co.yield(count)
  end
  do_rects_stash:removeSelf()
  do_rects_stash = nil
end

local do_lines_stash
local line_new = Line.new

function scene.do_lines(self, count)
  do_lines_stash = display.newGroup()
  do_lines_stash.lines = {}
  local old_count = 0
  while count do
    for i = old_count + 1, count do
      local spot = i - 1
      local x_loc = (spot % 40) * 18.5
      local y_loc = floor(spot / 40) * 18 + 300
      local l = line_new(x_loc, y_loc, x_loc + 25, y_loc + 25, 2, i)
      l:setThickness(3)
      l.blendMode = 'add'
      do_lines_stash.lines[#do_lines_stash.lines + 1] = l
      do_lines_stash:insert(l)
      l:setTheta(i + count)
      l:redraw()
    end
    old_count = count
    for i = count - ceil(count / 4), count do 
      do_lines_stash.lines[i]:setTheta(i + count)
      do_lines_stash.lines[i]:redraw()
    end
    self, count = co.yield(count)
  end
  do_lines_stash:removeSelf()
  do_lines_stash = nil
end

local measuring

local benchmarks = {
  { name = 'baseline', base = 5000, inc = 5000, func = scene.do_nothing, max = 50000 },
  { name = 'line', base = 20, inc = 10, func = scene.do_lines, max = 1600 },
  { name = 'square', base = 20, inc = 20, func = scene.do_rects, max = 1600 },
  { name = 'hex', base = 20, inc = 20, func = scene.do_hexes, max = 1600 },
}

local stats = {
}

function scene:enterScene(event)
  self.help = display.newImage('benchmark.png')
  s:insert(self.help)
  self:state1("Please be patient -- gathering performance data.")
  self:state2("")
  self.view.alpha = 1
  measuring = 1
  Touch.ignore_prefs(true)
  Touch.ignore_doubletaps(true)
end

function scene.settings_complete()
  if not Settings.benchmark then
    return false
  end
  for i, bench in ipairs(benchmarks) do
    if not Settings.benchmark[bench.name] then
      return false
    end
  end
  return true
end

local last_frame
local proc
local per_frame = 1
local samples = {}
local averages = {}
local last_average = 0

function scene:enterFrame(event)
  local now = timer()
  if not last_frame then
    last_frame = now
    return
  end
  local bench = benchmarks[measuring]
  local elapsed = now - last_frame
  last_frame = now
  if not proc then
    if bench and bench.func then
      proc = co.create(bench.func)
      per_frame = bench.base
      samples[per_frame] = {}
      self:state1("Measuring %s.", bench.name)
      collectgarbage('collect')
    else
      self:state1("Done benchmarking.")
      Settings.benchmark = stats
      Settings:save()
      Modus.next_display()
      return
    end
  else
    local cur = samples[per_frame]
    cur[#cur + 1] = elapsed
    self:state2("%.1fms for %d repetitions.", elapsed, per_frame)
    if #cur >= 6 then
      local avg = 0
      -- disregard the first reported value, which seems to be wonky
      -- because of item creation
      table.remove(cur, 1)
      for idx, time in ipairs(cur) do
        avg = avg + time
      end
      -- we will tolerate one slipped frame per five
      avg = (avg - (60 / 1000)) / #cur
      if avg >= last_average or per_frame >= bench.max then
        averages[per_frame] = avg
	last_average = avg
      end
      -- Util.printf("Average for %d items: %.1fms", per_frame, avg)
      per_frame = per_frame + bench.inc
      if avg > 60 or per_frame > bench.max then
	-- we're done here
	stats[bench.name] = averages
	samples = {}
	averages = {}
	last_average = 0
	co.resume(proc, self, false)
	proc = nil
	measuring = measuring + 1
	-- pop out, let the next run through do setup
	return
      else
	samples[per_frame] = {}
        collectgarbage('collect')
      end
    end
  end
  co.resume(proc, self, per_frame)
end

function scene:exitScene(event)
  -- self.help:removeSelf()
  -- self.help = nil
  if self.state1text then
    self.state1text:removeSelf()
    self.state1text = nil
  end
  if self.state2text then
    self.state2text:removeSelf()
    self.state2text = nil
  end
end

function scene:destroyScene(event)
  self.bg = nil
end

return scene
