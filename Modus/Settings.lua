local Settings = {}

local floor = math.floor
local ceil = math.ceil

local json = require('json')

Settings.default = {
  frame_delay = 2,
  touch_accel = 1,
  points = 1,
  v_min = 5,
  v_max = 15,
  color_multiplier = 1,
  history = 6,
  enabled = true,
  timbre = 'breath',
  palette = 'rainbow',
  line_thickness = 3,
  line_depth = 2,
  square_type = 2,
  linear = 0.01,
  quadratic = 0.01,
}

Settings.scene_defaults = {
  benchmark = {
    frame_delay = 1,
  },
  firebugs = {
    color_multiplier = 16,
    frame_delay = 4,
    square_type = 1,
    type = 'square',
    quadratic = 1,
    linear = 1,
  },
  fire = {
    color_multiplier = 16,
    frame_delay = 4,
    square_type = 1,
    type = 'square',
    quadratic = 1,
    linear = 1,
  },
  stringart = {
    points = 3,
    color_multiplier = 9,
    history = 1,
    v_min = 10,
    v_max = 20,
    frame_delay = 3,
    type = 'line',
  },
  spiral = {
    points = 3,
    history = 8,
    color_multiplier = 16,
    frame_delay = 3,
    type = 'line',
  },
  spiral2 = {
    points = 3,
    history = 8,
    color_multiplier = 16,
    frame_delay = 3,
    type = 'line',
  },
  knights = {
    frame_delay = 12,
    type = 'square',
  },
  knights2 = {
    frame_delay = 12,
    type = 'square',
  },
  spline = {
    history = 16,
    color_multiplier = 20,
    type = 'line',
  },
  cascade = {
    frame_delay = 12,
    color_multiplier = 12,
    type = 'square',
  },
  cascade2 = {
    frame_delay = 8,
    color_multiplier = 12,
    type = 'square',
  },
  drops = {
    total_drops = #Rainbow.hues * 3,
    drop_threshold = #Rainbow.hues * 3 - 5,
    min_cooldown = 10,
    max_cooldown = 40,
    max_growth = 125,
    min_growth = 45,
  },
  lines = {
    color_multiplier = 8,
    history = 1,
    v_min = 10,
    v_max = 20,
    type = 'line',
  },
  lissajous = {
    history = 8,
    color_multiplier = 24,
    sound_delay = 9,
    delta_delta = 0.1,
    frame_delay = 3,
    type = 'line',
  },
  ants = {
    color_multiplier = 7,
    ants = 6,
    frame_delay = 5,
    type = 'hex',
    linear = 2,
  },
  ants2 = {
    color_multiplier = 7,
    ants = 6,
    frame_delay = 5,
    type = 'hex',
    linear = 2,
  },
}

Settings.default_overrides = {
}

Settings.scene_overrides = {
}

Settings.file_path = system.pathForFile('settings.json', system.DocumentsDirectory)

-- clean up benchmark tables
function Settings.interpolate()
  Settings.bindex = {}
  Settings.interpolated = {}
  for key, benchmark in pairs(Settings.benchmark) do
    Settings.bindex[key], Settings.interpolated[key] = Settings.interpolate_one(benchmark)
    Settings.bindex[key].name = key
  end
end

function Settings.interpolate_one(benchmark)
  local counts = {}
  local count_to_msec = {}
  for count, msec in pairs(benchmark) do
    count = tonumber(count)
    msec = tonumber(msec)
    counts[#counts + 1] = count
    count_to_msec[count] = msec
  end
  table.sort(counts)
  counts.lowest = counts[1]
  counts.highest = counts[#counts]
  counts.middle = ceil((counts.lowest + counts.highest) / 2)
  counts.msecs = count_to_msec
  count_to_msec.index = counts
  return counts, count_to_msec
end

function Settings.estimate(benchmark, value)
  if not benchmark then
    return 60
  end
  local index = benchmark.index
  local below, above, below_msec, above_msec
  for i = 1, #index do
    local count = index[i]
    if count == value then
      return benchmark[count]
    end
    if count < value then
      below = count
      below_msec = benchmark[count]
    end
    if count > value and not above then
      above = count
      above_msec = benchmark[count]
      break
    end
  end
  if below and above then
    local scale = (value - below) / (above - below)
    return (above_msec * scale) + (below_msec * (1 - scale))
  end
  if below then
    return below_msec * (value / below)
  end
  if above then
    return above_msec * (value / above)
  end
  Util.printf("Found no values anywhere near %d, keys are %s.", value, table.concat(index, ", "))
  return 60
end

function Settings.load()
  local stream = io.open(Settings.file_path, "r")
  if stream then
    stream_json = stream:read("*a")
    io.close(stream)
    local data, _, errors = json.decode(stream_json, 1, nil, {}, {})
    if data then
      Settings.default_overrides = data.default
      Settings.scene_overrides = data.scene
      Settings.benchmark = data.benchmark
      Settings.interpolate()
      return true
    end
  end
  return false
end

function Settings.save()
  local data = { default = Settings.default_overrides, scene = Settings.scene_overrides, benchmark = Settings.benchmark }
  local data_json = json.encode(data)
  local stream = io.open(Settings.file_path, "w")
  if stream then
    stream:write(data_json)
    io.close(stream)
  end
end

function Settings.time_for(benchmark, count, linear, quadratic)
  local base_msec, linear_time, quadratic_time = 0, 0, 0
  base_msec = Settings.estimate(benchmark, count)
  if linear then
    linear_msec = Settings.estimate(Settings.interpolated.linear, count) * linear
  end
  if quadratic then
    quadratic_msec = Settings.estimate(Settings.interpolated.quadratic, count) * quadratic
  end
  Util.printf("%d items: %.1f + %.1f ms + %.1f ms => %.1fms",
    count, base_msec, linear_msec, quadratic_msec,
    base_msec + linear_msec + quadratic_msec)
  return base_msec + linear_msec + quadratic_msec
end

function Settings.items_for(ideal_time, benchmark, linear, quadratic)
  local best_count
  local best_msec = 1000
  local linear_time = 0
  local quadratic_time = 0
  local index = benchmark.index

  Util.printf("items_for: %.1fms.", ideal_time)
  local lowest_count, lowest_msec = index.lowest, benchmark[index.lowest]
  local highest_count, highest_msec = index.highest, benchmark[index.highest]
  local current_count, current_msec, base_msec, crunch_msec
  linear_msec = 0
  quadratic_msec = 0
  current_count = index.middle
  highest_msec = Settings.time_for(benchmark, highest_count, linear, quadratic)
  if highest_msec < ideal_time then
    Util.printf("Highest time is %.1fms, using %d.", highest_msec, highest_count)
    return highest_count, highest_msec
  end
  current_msec = Settings.time_for(benchmark, current_count, linear, quadratic)
  local tries = 1
  while current_msec > ideal_time or (ideal_time - current_msec > 3) do
    tries = tries + 1
    if tries > 10 then
      Util.printf("Giving up after 10 tries.")
      break
    end
    Util.printf("Considering %d items: %.1fms, compared to %.1fms.",
      current_count, current_msec, ideal_time)
    if current_msec > ideal_time then
      highest_count = current_count
      highest_msec = current_msec
      current_count = (current_count + lowest_count) / 2
    else
      lowest_count = current_count
      lowest_msec = current_msec
      current_count = (current_count + highest_count) / 2
    end
    current_msec = Settings.time_for(benchmark, current_count, linear, quadratic)
  end
  return current_count, current_msec
end

function Settings.compute_properties(set, benchmark)
  -- trim it a bit because otherwise we tend to run over...
  Util.printf("computing: %s", tostring(set.type))
  local ideal_time = (set.frame_delay * Settings.frametime) * .85
  local linear = set.linear or 0.2
  local quadratic = set.quadratic or 0.01
  if set.type == 'line' then
    local orig_color_multiplier = set.color_multiplier
    local orig_history = set.history
    local giving_up = false
    -- lines have history (previous examples still up) and a
    -- color multiplier, and possibly a number of "points" (for
    -- instance, the 3 arms of the spiral mode).  number of lines
    -- onscreen will be points * history * multiplier
    local can_draw, expected_time = Settings.items_for(ideal_time, benchmark, linear, quadratic)
    while not giving_up do
      -- color_multiplier * 6 because color_multiplier multiplies colors
      local effective_n = set.points * set.history * set.color_multiplier * 6
      if effective_n < can_draw then
	Util.printf("Looking for time of %.1fms (%.2f+%.2f crunch) or less, got %d/%d lines in %.1fms.",
	    ideal_time, set.quadratic, set.linear, effective_n, can_draw, expected_time)
	return
      else
	-- scale back whichever has been scaled back less, starting with
	-- history
        if set.color_multiplier / orig_color_multiplier >
	   set.history / orig_history then
	  if set.color_multiplier >= orig_color_multiplier / 3 then
	    set.color_multiplier = set.color_multiplier - 1
	  else
	    giving_up = true
	  end
        else
	  if set.history > orig_history / 3 then
	    set.history = set.history - 1
	  else
	    giving_up = true
	  end
	end
      end
    end
  elseif set.type == 'square' or set.type == 'hex' then
    local msec
    set.max_items, msec = Settings.items_for(ideal_time, benchmark, linear, quadratic)
    Util.printf("Looking for time of %.1fms (%.2f+%.2f crunch) or less, got %d items in %.1fms.",
    	ideal_time, set.quadratic, set.linear, set.max_items, msec)
  end
end

function Settings.scene(scene)
  Settings.frametime = (1000 / (display.fps or 60))
  local o = {}
  for k, v in pairs(Settings.default) do
    o[k] = v
  end
  if Settings.scene_defaults[scene] then
    for k, v in pairs(Settings.scene_defaults[scene]) do
      o[k] = v
    end
  end
  for k, v in pairs(Settings.default_overrides) do
    o[k] = v
  end
  Settings.scene_overrides[scene] = Settings.scene_overrides[scene] or {}
  o.setting_overrides = Settings.scene_overrides[scene]
  for k, v in pairs(o.setting_overrides) do
    o[k] = v
  end
  if o.frame_delay and o.type then
    bench = Settings.interpolated and Settings.interpolated[o.type]
    if bench then
      Settings.compute_properties(o, bench)
      -- Util.printf("Computed settings for %s frame delay %d", o.type, o.frame_delay)
    end
  end
  -- because everyone wants to know
  o.total_colors = #Rainbow.hues * o.color_multiplier
  return o
end

return Settings
