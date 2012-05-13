local Settings = {}

Settings.default = {
  frame_delay = 2,
  touch_accel = 1,
  v_min = 5,
  v_max = 15,
  color_multiplier = 1,
  history = 6,
  tone = 'breath',
}

Settings.scenes = {
  spiral = {
    points = 3,
    history = 6,
    color_multiplier = 10,
  },
  spiral2 = {
    points = 3,
    history = 6,
    color_multiplier = 10,
  },
  knights = {
    frame_delay = 12,
  },
  knights2 = {
    frame_delay = 12,
  },
  spline = {
    history = 16,
    color_multiplier = 6
  },
  cascade = {
    frame_delay = 12,
    color_multiplier = 12,
  },
  cascade2 = {
    frame_delay = 8,
    color_multiplier = 12,
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
    v_min = 10,
    v_max = 20,
  },
  lissajous = {
    history = 8,
    color_multiplier = 16,
    sound_delay = 3,
    delta_delta = 0.1,
    frame_delay = 3,
  },
  ants = {
    color_multiplier = 4,
    ants = 6,
    frame_delay = 5,
    sound_delay = 4,
  },
  ants2 = {
    color_multiplier = 4,
    ants = 6,
    frame_delay = 5,
    sound_delay = 4,
  },
}

function Settings.scene(scene)
  local o = {}
  for k, v in pairs(Settings.default) do
    o[k] = v
  end
  if Settings.scenes[scene] then
    for k, v in pairs(Settings.scenes[scene]) do
      o[k] = v
    end
  end
  -- because everyone wants to know
  o.total_colors = #Rainbow.hues * o.color_multiplier
  return o
end

return Settings
