local Settings = {}

Settings.default = {
  frame_delay = 2,
}

Settings.scenes = {
  spiral = {
    points = 3,
  }
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
