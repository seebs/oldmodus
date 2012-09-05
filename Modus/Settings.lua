local Settings = {}

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
}

Settings.scene_defaults = {
  benchmark = {
    frame_delay = 1,
  },
  spiral = {
    points = 3,
    history = 7,
    color_multiplier = 14,
    frame_delay = 3,
    type = 'line',
  },
  spiral2 = {
    points = 3,
    history = 7,
    color_multiplier = 14,
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
    color_multiplier = 6,
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
    max_cooldown = 30,
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
    color_multiplier = 4,
    ants = 6,
    frame_delay = 5,
    sound_delay = 20,
    type = 'hex',
  },
  ants2 = {
    color_multiplier = 4,
    ants = 6,
    frame_delay = 5,
    sound_delay = 20,
    type = 'hex',
  },
}

Settings.default_overrides = {
}

Settings.scene_overrides = {
}

Settings.file_path = system.pathForFile('settings.json', system.DocumentsDirectory)

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

function Settings.items_for(ideal_time, benchmark)
  local best_count
  local best_msec = 1000

  Util.printf("items_for: %.1fms.", ideal_time)
  for count, msec in pairs(benchmark) do
    count = tonumber(count)
    msec = tonumber(msec)
    if best_count then
      if msec < ideal_time and count > best_count then
        -- Util.printf("have %d in %.1fms, prefer %d in %.1fms",
        --   best_count, best_msec, count, msec)
        best_count = count
	best_msec = msec
      -- else
        -- Util.printf("have %d in %.1fms, don't want %d in %.1fms",
        --   best_count, best_msec, count, msec)
      end
    else
      best_count = count
      best_msec = msec
    end
  end
  if best_msec == 1000 then
    -- we didn't find anything under ideal_time? geeze.
    return 100, 1000
  else
    return best_count, best_msec
  end
end

function Settings.time_for(n, benchmark)
  local best_count
  local best_msec = 1000
  local highest_count = 0
  for count, msec in pairs(benchmark) do
    count = tonumber(count)
    msec = tonumber(msec)
    if best_count then
      if count > n and msec < best_msec then
        -- Util.printf("have %d in %.1fms, prefer %d in %.1fms",
          -- best_count, best_msec, count, msec)
        best_count = count
	best_msec = msec
      -- else
        -- Util.printf("have %d in %.1fms, don't want %d in %.1fms",
          -- best_count, best_msec, count, msec)
      end
    else
      best_count = count
      best_msec = msec
    end
    if best_count > highest_count then
      highest_count = best_count
    end
  end
  if best_msec == 1000 then
    -- maybe we got lucky
    return Settings.frametime
  else
    if n > highest_count then
      -- scale to actual N, if N is larger than anything the benchmark tried
      return best_msec * n / highest_count
    else
      return best_msec
    end
  end
end

function Settings.compute_properties(set, benchmark)
  -- trim it a bit because otherwise we tend to run over...
  local ideal_time = (set.frame_delay * Settings.frametime) * .85
  if set.type == 'line' then
    local orig_color_multiplier = set.color_multiplier
    local orig_history = set.history
    local giving_up = false
    -- lines have history (previous examples still up) and a
    -- color multiplier, and possibly a number of "points" (for
    -- instance, the 3 arms of the spiral mode).  number of lines
    -- onscreen will be points * history * multiplier
    while not giving_up do
      -- color_multiplier * 6 because color_multiplier multiplies colors
      local effective_n = set.points * set.history * set.color_multiplier * 6
      local delay = Settings.time_for(effective_n, benchmark)
      -- Util.printf("Considering %d points, %d history, %d colors (%d lines), expecting %.1fms.",
      --   set.points, set.history, set.color_multiplier, effective_n, delay)
      if delay <= ideal_time then
        Util.printf("Looking for %.1fms, expecting %.1fms for %d lines.",
          ideal_time, delay, effective_n)
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
    set.max_items, msec = Settings.items_for(ideal_time, benchmark)
    Util.printf("Looking for time of %.1fms or less, got %d items in %.1fms.",
    	ideal_time, set.max_items, msec)
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
    bench = Settings.benchmark and Settings.benchmark[o.type]
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
