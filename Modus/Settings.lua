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
  tone = 'breath',
}

Settings.scene_defaults = {
  benchmark = {
    frame_delay = 1,
  },
  spiral = {
    points = 3,
    history = 9,
    color_multiplier = 16,
    type = 'line',
  },
  spiral2 = {
    points = 3,
    history = 9,
    color_multiplier = 16,
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
    color_multiplier = 16,
    sound_delay = 3,
    delta_delta = 0.1,
    frame_delay = 3,
    type = 'line',
  },
  ants = {
    color_multiplier = 4,
    ants = 6,
    frame_delay = 5,
    sound_delay = 4,
    type = 'hex',
  },
  ants2 = {
    color_multiplier = 4,
    ants = 6,
    frame_delay = 5,
    sound_delay = 4,
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

function Settings.time_for(n, benchmark)
  local best_count
  local best_msec = 1000
  for count, msec in pairs(benchmark) do
    if best_count then
      if tonumber(count) > n and tonumber(msec) < best_msec then
        best_count = count
	best_msec = msec
      end
    else
      best_count = count
      best_msec = msec
    end
  end
  if best_msec == 1000 then
    -- maybe we got lucky
    return Settings.frametime
  else
    return best_msec
  end
end

function Settings.compute_properties(set, benchmark)
  local ideal_time = set.frame_delay * Settings.frametime
  if set.type == 'line' then
    local orig_color_multiplier = set.color_multiplier
    local orig_history = set.history
    local giving_up = false
    -- lines have history (previous examples still up) and a
    -- color multiplier, and possibly a number of "points" (for
    -- instance, the 3 arms of the spiral mode).  number of lines
    -- onscreen will be points * history * multiplier
    while not giving_up do
      local effective_n = set.points * set.history * set.color_multiplier
      local delay = Settings.time_for(effective_n, benchmark)
      Util.printf("Considering effective display of %d lines, expecting %.1fms.",
        effective_n, delay)
      if delay <= ideal_time then
	return
      else
	-- scale back whichever has been scaled back less, starting with
	-- history
        if set.color_multiplier / orig_color_multiplier >
	   set.history / orig_history then
	  if set.color_multiplier > orig_color_multiplier / 2 then
	    set.color_multiplier = set.color_multiplier - 1
	  else
	    giving_up = true
	  end
        else
	  if set.history > orig_history / 2 then
	    set.history = set.history - 1
	  else
	    giving_up = true
	  end
	end
      end
    end
  else
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
  if Settings.scene_overrides[scene] then
    for k, v in pairs(Settings.scene_overrides[scene]) do
      o[k] = v
    end
  end
  if o.frame_delay and o.type then
    bench = Settings.benchmark[o.type]
    if bench then
      Settings.compute_properties(o, bench)
      Util.printf("computed settings for frame delay %d", o.frame_delay)
    end
  end
  -- because everyone wants to know
  o.total_colors = #Rainbow.hues * o.color_multiplier
  return o
end

return Settings
