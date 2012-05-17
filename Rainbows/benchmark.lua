local scene = {}

local frame = Util.enterFrame
local touch = Touch.state

local s
local set

local sprintf = Util.sprintf
local timer = system.getTimer
local co = coroutine
local to_s = tostring
local floor = math.floor

function scene:createScene(event)
  s = self.screen
  set = self.settings

  -- so clicks have something to land on
  self.bg = display.newRect(s, 0, 0, s.size.x, s.size.y)
  self.bg:setFillColor(0, 0)
  self.view:insert(self.bg)
end

function scene:touch_magic(state)
  if state.events > 0 then
    next_display()
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

local do_rects_stash
local rect_new = display.newRect

function scene.do_rects(self, count)
  do_rects_stash = display.newGroup()
  do_rects_stash.rects = {}
  local old_count = 0
  while count do
    for i = old_count + 1, count do
      local spot = i - 1
      local x_loc = (spot % 19) * 40
      local y_loc = floor(spot / 19) * 40 + 250
      local l = rect_new(s, x_loc, y_loc, 30, 30)
      l:setFillColor(120, 120, 255)
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
      local x_loc = (spot % 19) * 40
      local y_loc = floor(spot / 19) * 40 + 250
      local l = line_new(x_loc, y_loc, x_loc + 35, y_loc + 35, 5, 120, 120, 255)
      l.blendMode = 'add'
      do_lines_stash.lines[#do_lines_stash.lines + 1] = l
      do_lines_stash:insert(l)
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
  { name = 'baseline', base = 5000, inc = 5000, func = scene.do_nothing, max = 50000 },
  { name = 'lines', base = 10, inc = 5, func = scene.do_lines, max = 400 },
  { name = 'rectangles', base = 20, inc = 10, func = scene.do_rects, max = 500 },
}

local stats = {
}

function scene:enterScene(event)
  self.help = display.newImage('benchmark.png')
  s:insert(self.help)
  self:state1("Please be patient -- gathering performance data.")
  self:state2("")
  measuring = 1
  Touch.ignore_prefs(true)
  Touch.ignore_doubletaps(true)
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
    else
      self:state1("Done benchmarking.")
      Settings.default_overrides.benchmark = stats
      Settings:save()
      next_display()
      return
    end
  else
    local cur = samples[per_frame]
    cur[#cur + 1] = elapsed
    self:state2("%.1fms for %d repetitions.", elapsed, per_frame)
    if #cur >= 5 then
      local avg = 0
      for idx, time in ipairs(cur) do
        avg = avg + time
      end
      avg = avg / #cur
      if avg > last_average or per_frame > bench.max then
        averages[per_frame] = avg
	last_average = avg
      end
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
      end
    end
  end
  co.resume(proc, self, per_frame)
end

function scene:exitScene(event)
  self.help:removeSelf()
  self.help = nil
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
