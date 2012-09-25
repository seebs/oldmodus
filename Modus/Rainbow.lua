local Rainbow = {}

Rainbow.manyhues = {
  rainbow = {
    { 255, 0, 0 },
    { 240, 90, 0 },
    { 220, 220, 0 },
    { 0, 200, 0 },
    { 0, 0, 255 },
    { 180, 0, 200 },
  },
  pastel = {
    { 255, 128, 128 },
    { 255, 150, 128 },
    { 240, 240, 108 },
    { 128, 200, 128 },
    { 128, 128, 255 },
    { 200, 128, 220 },
  },
  ocean = {
    { 0, 0, 255 },
    { 40, 80, 255 },
    { 0, 180, 40 },
    { 0, 200, 200 },
    { 0, 180, 255 },
    { 140, 0, 240 },
  },
  earth = {
    { 70, 100, 40 },
    { 220, 160, 45 },
    { 130, 90, 40 },
    { 100, 50, 30 },
    { 210, 110, 0 },
    { 150, 60, 30 },
  },
}

Rainbow.names = {
  rainbow = "Rainbow", ocean = "Ocean", pastel = "Pastel", earth = "Earth",
}

function Rainbow.list()
  local names = {}
  for name, count in pairs(Rainbow.names) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names, Rainbow.names
end

Rainbow.hues = Rainbow.manyhues.rainbow

Rainbow.smoothed = {}
Rainbow.funcs = {}

local floor = math.floor
local ceil = math.ceil
local abs = math.abs
local min = math.min
local max = math.max

function Rainbow.funcs_for(denominator)
  if #Rainbow.hues ~= 6 then
    Util.printf("Uh-oh!  Assumptions being broken.")
  end
  if not Rainbow.smoothed[denominator] then
    Rainbow.smoothify(denominator)
    Rainbow.funcs[denominator] = {}
    local t = Rainbow.smoothed[denominator]
    local n = 6 * denominator
    Rainbow.funcs[denominator].smoothobj = function(o, hue)
      local v = t[((floor(hue) - 1) % n) + 1]
      o.r, o.g, o.b = v[1], v[2], v[3]
    end
    Rainbow.funcs[denominator].setsmoothobj = function(o, hue)
      local v = t[((floor(hue) - 1) % n) + 1]
      o:setFillColor(v[1], v[2], v[3])
    end
    Rainbow.funcs[denominator].smooth = function(hue)
      local v = t[((floor(hue) - 1) % n) + 1]
      return v[1], v[2], v[3]
    end
    Rainbow.funcs[denominator].dist = function(hue1, hue2)
      local h1 = (hue1 - 1) % n + 1
      local h2 = (hue2 - 1) % n + 1
      if h1 == h2 then
        return 0
      end
      if h2 > h1 then
        return min(h2 - h1, (h1 + n - h2))
      else
        return min(h1 - h2, (h2 + n - h1))
      end
    end
    Rainbow.funcs[denominator].towards = function(hue1, hue2)
      local h1 = (hue1 - 1) % n + 1
      local h2 = (hue2 - 1) % n + 1
      if h1 == h2 then
        return h1
      end
      if h2 < h1 then
        h2 = h2 + n
      end
      if h2 - h1 < n / 2 then
        return (h1 % n) + 1
      else
        return ((h1 - 2) % n) + 1
      end
    end
  end
  return Rainbow.funcs[denominator]
end

function Rainbow.smoothify(denominator)
  local tab = Rainbow.smoothed[denominator] or {}
  if denominator == 1 and not Rainbow.smoothed[denominator] then
    Rainbow.smoothed[denominator] = { unpack(Rainbow.hues) }
    return
  end
  for hue = 1, #Rainbow.hues * denominator do
    local hue1 = floor(hue / denominator)
    local hue2 = ceil((hue + 1) / denominator)
    local increment = hue % denominator
    local inverse = denominator - increment
    local color1 = Rainbow.hues[hue1] or Rainbow.hues[6]
    local color2 = Rainbow.hues[hue2] or Rainbow.hues[1]
    local r = color1[1] * inverse + color2[1] * increment
    local g = color1[2] * inverse + color2[2] * increment
    local b = color1[3] * inverse + color2[3] * increment
    if tab[hue] then
      tab[hue][1] = ceil(r / denominator)
      tab[hue][2] = ceil(g / denominator)
      tab[hue][3] = ceil(b / denominator)
    else
      tab[hue] = { ceil(r / denominator), ceil(g / denominator), ceil(b / denominator) }
    end
  end
  Rainbow.smoothed[denominator] = tab
end

function Rainbow.change_palette(palette)
  if Rainbow.manyhues[palette] then
    Rainbow.hues = Rainbow.manyhues[palette]
    for idx, tab in pairs(Rainbow.smoothed) do
      Rainbow.smoothify(idx)
    end
  end
end

function Rainbow.setsmoothobj(o, hue, denominator)
  if not Rainbow.smoothed[denominator] then
    Rainbow.smoothify(denominator)
  end
  local v = Rainbow.smoothed[denominator][((hue - 1) % (#Rainbow.hues * denominator)) + 1]
  o:setFillColor(v[1], v[2], v[3])
end

function Rainbow.smoothobj(o, hue, denominator)
  if not Rainbow.smoothed[denominator] then
    Rainbow.smoothify(denominator)
  end
  local v = Rainbow.smoothed[denominator][((hue - 1) % (#Rainbow.hues * denominator)) + 1]
  o.r, o.g, o.b = v[1], v[2], v[3]
end

function Rainbow.smooth(hue, denominator)
  if not Rainbow.smoothed[denominator] then
    Rainbow.smoothify(denominator)
  end
  hue = ((hue - 1) % (#Rainbow.hues * denominator)) + 1
  return Rainbow.smoothed[denominator][hue]
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

function Rainbow.colorobj(o, idx)
  local v = Rainbow.hues[((idx - 1) % #Rainbow.hues) + 1]
  o.r, o.g, o.b = v[1], v[2], v[3]
end

function Rainbow.setcolorobj(o, idx)
  local v = Rainbow.hues[((idx - 1) % #Rainbow.hues) + 1]
  o:setFillColor(v[1], v[2], v[3])
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
