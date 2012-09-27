local scene = {}

scene.AVERAGE_TRIALS = 9

local frame = Util.enterFrame
local touch = Touch.state

local s
local set

local sprintf = Util.sprintf
local printf = Util.printf
local timer = system.getTimer
local co = coroutine
local to_s = tostring
local to_n = tonumber
local floor = math.floor
local ceil = math.ceil

function scene:createScene(event)
  s = self.screen
  set = self.settings
end

function scene:touch_magic(state)
  if state.events > 0 then
    Logic.next_display()
  end
end

function scene:state1(fmt, ...)
  if not self.state1text then
    self.state1text = display.newText('', Screen.center.x, Screen.center.y, native.defaultFont, 30)
    s:insert(self.state1text)
  end
  local t = sprintf(fmt, ...)
  -- print("s1: " .. t)
  self.state1text.text = t
  self.state1text:setReferencePoint(display.TopLeftReferencePoint)
  self.state1text.x = 10
  self.state1text.y = 220
end

function scene:state2(fmt, ...)
  if not self.state2text then
    self.state2text = display.newText('', Screen.center.x, Screen.center.y, native.defaultFont, 30)
    s:insert(self.state2text)
  end
  local t = sprintf(fmt, ...)
  -- print("s2: " .. t)
  self.state2text.text = t
  self.state2text:setReferencePoint(display.TopLeftReferencePoint)
  self.state2text.x = 10
  self.state2text.y = 260
end

function scene.do_nothing(self, count)
  local j
  local old_count = 0
  while count do
    for i = old_count + 1, count do 
      j = to_s(i)
    end
    old_count = count
    self, count = co.yield(count)
  end
end

function scene.do_something1(self, count)
  local j, k, l
  local s
  local old_count = 0
  while count do
    local x = {}
    local y = {}
    for i = old_count + 1, count do 
      y[i] = to_s(i)
    end
    s = to_s(count)
    for j = 1, count do
      x[j] = s .. tostring(j)
      for k = j - 5, j do
	if x[j] then
	  y[k] = to_n(x[j])
	end
      end
    end
    old_count = count
    collectgarbage('collect')
    self, count = co.yield(count)
  end
end

function scene.do_something2(self, count)
  local j, k, l
  local s
  local old_count = 0
  while count do
    local x = {}
    local y = {}
    for i = old_count + 1, count do 
      y[i] = to_s(i)
    end
    s = to_s(count)
    for j = 1, count do
      x[j] = s .. tostring(j)
      for k = j, floor(j + count / 100) do
	y[k] = to_n(x[j])
      end
    end
    old_count = count
    collectgarbage('collect')
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
      local x_loc = (spot % 61) * 12.5 + 10
      local y_loc = floor(spot / 61) * 12.5 + 320
      local l = display.newImage(hexsheet, 1)
      l.x = x_loc
      l.y = y_loc
      l.xScale = 20 / 256
      l.yScale = 20 / 256
      l:setFillColor(unpack(Rainbow.color(i)))
      l.alpha = ((i % 7) + 1) / 7
      do_hexes_stash.hexes[#do_hexes_stash.hexes + 1] = l
      do_hexes_stash:insert(l)
    end
    old_count = count
    for i = 1, count do 
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
      local x_loc = (spot % 61) * 12.5
      local y_loc = floor(spot / 61) * 12.5 + 300
      local l = rect_new(s, x_loc, y_loc, 15, 15)
      l:setFillColor(unpack(Rainbow.color(i)))
      l.alpha = 0.4
      l.blendMode = 'add'
      do_rects_stash.rects[#do_rects_stash.rects + 1] = l
      do_rects_stash:insert(l)
    end
    old_count = count
    for i = 1, count do 
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
      local x_loc = (spot % 61) * 12.5
      local y_loc = floor(spot / 61) * 12.5 + 300
      local l = line_new(x_loc, y_loc, x_loc + 20, y_loc + 20, set.line_depth, i)
      l:setThickness(4)
      l.blendMode = 'add'
      do_lines_stash.lines[#do_lines_stash.lines + 1] = l
      do_lines_stash:insert(l)
      l:setTheta(i + count)
      l:redraw()
    end
    old_count = count
    for i = 1, count do 
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
  { name = 'baseline', base = 1000, inc = 1000, func = scene.do_nothing, max = 15000 },
  { name = 'linear', base = 30, inc = 30, func = scene.do_something1, max = 3600 },
  { name = 'quadratic', base = 30, inc = 30, func = scene.do_something2, max = 3600 },
  { name = 'line', base = 30, inc = 30, func = scene.do_lines, max = 3600 },
  { name = 'square', base = 30, inc = 30, func = scene.do_rects, max = 3600 },
  { name = 'hex', base = 30, inc = 30, func = scene.do_hexes, max = 3600 },
}

local stats = {
}

function scene:enterScene(event)
  self.help = display.newImage('benchmark.png', 0, 0, true)
  s:insert(self.help)
  self:state1("Please be patient -- gathering performance data.")
  self:state2("")
  self.view.alpha = 1
  measuring = 1
  Touch.ignore_prefs(true)
  Touch.ignore_doubletaps(true)
  Touch.disable(true)
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
local last_per_frame = 0
local per_frame_inc = 1
local creating = false

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
      per_frame_inc = bench.inc
      samples[per_frame] = {}
      self:state1("Measuring %s.", bench.name)
      collectgarbage('collect')
      creating = true
      last_frame = timer()
    else
      self:state1("Done benchmarking.")
      Settings.benchmark = stats
      Settings.save()
      Settings.interpolate()
      Logic.reload_display()
      return
    end
  else
    local cur = samples[per_frame]
    -- ignore any sample after we created new items
    if creating then
      creating = false
    else
      cur[#cur + 1] = elapsed
    end
    if #cur >= scene.AVERAGE_TRIALS + 1 then
      Sounds.play(per_frame, 0.1)
      local avg = 0
      -- disregard the first reported value, which seems to be wonky
      -- because of item creation
      cur[1] = 0
      for idx, time in ipairs(cur) do
        avg = avg + time
      end
      avg = avg / scene.AVERAGE_TRIALS
      self:state2("%s: %.1fms average for %d repetitions.", bench.name, avg, per_frame)
      if (avg / last_average) < 0.8 then
        -- the previous number was probably a glitch? Toss it.
	averages[last_per_frame] = nil
	last_average = 0
      end
      if avg >= last_average or (per_frame + per_frame_inc) >= bench.max then
        averages[per_frame] = avg
	last_average = avg
	last_per_frame = per_frame
      end
      Util.printf("%s average for %d: %.1fms", bench.name, per_frame, avg)
      per_frame = per_frame + per_frame_inc
      per_frame_inc = ceil(per_frame_inc * 1.05)
      -- some modes are as slow as 12 frames, ~= 0.2 seconds or 200ms
      if avg > 220 or per_frame > bench.max then
	-- we're done here
	stats[bench.name] = averages
	Util.printf("  *** %s ***", bench.name)
	for frames, millis in pairs(averages) do
	  Util.printf("    %d: %.1f", frames, millis)
	end
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
        creating = true
      end
    end
  end
  co.resume(proc, self, per_frame)
end

function scene:exitScene(event)
  self.help:removeSelf()
  self.help = nil
  if do_lines_stash then
    do_lines_stash:removeSelf()
    do_lines_stash = nil
  end
  if do_rects_stash then
    do_rects_stash:removeSelf()
    do_rects_stash = nil
  end
  if do_hexes_stash then
    do_hexes_stash:removeSelf()
    do_hexes_stash = nil
  end
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
