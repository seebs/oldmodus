Rainbow = {}

Rainbow.hues = {
  { 255, 0, 0 },
  { 240, 110, 0 },
  { 220, 220, 0 },
  { 0, 200, 0 },
  { 0, 0, 255 },
  { 180, 0, 200 },
}

function Rainbow.smooth(hue, denominator)
  hue = ((hue - 1) % (#Rainbow.hues * denominator)) + 1
  local hue1 = math.floor(hue / denominator)
  local hue2 = math.ceil((hue + 1) / denominator)
  local increment = hue % denominator
  local color1 = Rainbow.hues[hue1] or Rainbow.hues[6]
  local color2 = Rainbow.hues[hue2] or Rainbow.hues[1]
  local r = color1[1] * (denominator - increment) + color2[1] * increment
  local g = color1[2] * (denominator - increment) + color2[2] * increment
  local b = color1[3] * (denominator - increment) + color2[3] * increment
  return { math.ceil(r / denominator), math.ceil(g / denominator), math.ceil(b / denominator) }
end

function Rainbow.towards(hue1, hue2)
  hue1 = ((hue1 - 1 + #Rainbow.hues) % #Rainbow.hues) + 1
  hue2 = ((hue2 - 1 + #Rainbow.hues) % #Rainbow.hues) + 1
  if hue2 == hue1 then
    return hue1
  end
  if hue2 < hue1 then
    hue2 = hue2 + 6
  end
  if hue2 - hue1 < 3 then
    return ((hue1) % #Rainbow.hues) + 1
  else
    return ((hue1 - 2) % #Rainbow.hues) + 1
  end
end

function Rainbow.color(idx)
  return Rainbow.hues[((idx - 1) % #Rainbow.hues) + 1]
end

function Rainbow.colors(state, value)
  if not state then
    return Rainbow.colors, { hue = 0 }, nil
  end
  state.hue = state.hue + 1
  return Rainbow.hues[state.hue]
end

return Rainbow
