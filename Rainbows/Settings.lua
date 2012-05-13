local Settings = {}

Settings.default = {
  frame_delay = 2,
  touch_accel = 1,
  v_min = 5,
  v_max = 15,
  color_multiplier = 1,
  history = 6,
  tone = 'breath'
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
  return o
end

return Settings
