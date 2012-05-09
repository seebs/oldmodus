local Rainbow = {}

Rainbow.hues = {
  { 255, 0, 0 },
  { 240, 90, 0 },
  { 220, 220, 0 },
  { 0, 200, 0 },
  { 0, 0, 255 },
  { 180, 0, 200 },
}

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
      local v = t[((hue - 1) % n) + 1]
      o.r, o.g, o.b = v[1], v[2], v[3]
    end
    Rainbow.funcs[denominator].setsmoothobj = function(o, hue)
      local v = t[((hue - 1) % n) + 1]
      o:setFillColor(v[1], v[2], v[3])
    end
    Rainbow.funcs[denominator].smooth = function(hue)
      local v = t[((hue - 1) % n) + 1]
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
  local tab = {}
  if denominator == 1 then
    Rainbow.smoothed[denominator] = Rainbow.hues
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
    tab[hue] = { ceil(r / denominator), ceil(g / denominator), ceil(b / denominator) }
  end
  Rainbow.smoothed[denominator] = tab
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
