local Vector = {}

Vector.__index = Vector

local dist = Util.dist
local sprintf = Util.sprintf

function Vector.random_velocity(settings)
  local d = math.random(settings.v_max - settings.v_min) + settings.v_min
  if math.random(2) == 2 then
    d = d * -1
  end
  return d
end

function Vector:set_target(target, steps)
  local dx = target.x - self.x
  local dy = target.y - self.y
  self.dx = (dx / steps)
  self.dy = (dy / steps)
  self.distance = dist(self, target) / steps
  self.target = { x = target.x, y = target.y }
end

function Vector.move(vec, toward)
  local bounce_x, bounce_y, bounce_theta = false, false, false
  local accel = vec.settings.touch_accel or 2

  if vec.target then
    vec.controlled = true
  elseif toward then
    if toward.x > vec.x then
      vec.dx = vec.dx + accel
      if vec.dx == 0 then
        vec.dx = 1
      end
    elseif toward.x < vec.x then
      vec.dx = vec.dx - accel
      if vec.dx == 0 then
        vec.dx = -1
      end
    end
    if toward.y > vec.y then
      vec.dy = vec.dy + accel
      if vec.dy == 0 then
        vec.dy = 1
      end
    elseif toward.y < vec.y then
      vec.dy = vec.dy - accel
      if vec.dy == 0 then
        vec.dy = -1
      end
    end
    vec.controlled = true
  else
    vec.controlled = false
  end

  vec.x = vec.x + vec.dx
  vec.y = vec.y + vec.dy

  if vec.target then
    if dist(vec, vec.target) < vec.distance / 2 then
      return true
    end
  else
    if vec.x < vec.screen.left then
      bounce_x = true
      vec.x = vec.screen.left + (vec.screen.left - vec.x)
    elseif vec.x > vec.screen.right then
      bounce_x = true
      vec.x = vec.screen.right - (vec.x - vec.screen.right)
    end
    if vec.y < vec.screen.top then
      bounce_y = true
      vec.y = vec.screen.top + (vec.screen.top - vec.y)
    elseif vec.y > vec.screen.bottom then
      bounce_y = true
      vec.y = vec.screen.bottom - (vec.y - vec.screen.bottom)
    end
    Vector.coerce(vec, 'dx', bounce_x)
    Vector.coerce(vec, 'dy', bounce_y)
    if bounce_x then
      vec.dx = vec.dx * -1
    end
    if bounce_y then
      vec.dy = vec.dy * -1
    end
  end
  return bounce_x or bounce_y
end

function Vector.coerce(vec, member, big)
  local v = vec[member]
  local max_v = vec.settings.v_max / (vec.limiter or 1)
  local min_v = vec.settings.v_min / (vec.limiter or 1)
  local sign = v < 0
  local mag = sign and (0 - v) or v
  if big and not vec.controlled then
    if mag > max_v then
      mag = mag + math.random(2) - 3
    elseif mag < min_v then
      mag = mag + math.random(2)
    else
      mag = mag + math.random(3) - 2
    end
  else
    if mag > max_v then
      mag = mag + math.random(2) - 2
    elseif mag < min_v and not vec.controlled then
      mag = mag + math.random(2) - 1
    end
  end
  vec[member] = sign and (0 - mag) or mag
end

function Vector.coords(screen, settings, x, y)
  local o = Vector.random(screen, settings, 0)
  if y then
    o.x = x
    o.y = y
  else
    o.x = x.x
    o.y = x.y
  end
  return o
end

function Vector:copy()
  local o = {
    x = self.x,
    y = self.y,
    limiter = self.limiter,
    screen = self.screen,
    settings = self.settings,
    dx = self.dx,
    dy = self.dy,
  }
  if self.target then
    o.target = { x = self.target.x, y = self.target.y }
  end
  setmetatable(o, Vector)
  return o
end

function Vector.random(screen, settings, limiter)
  local o = {
    x = math.random(screen.size.x) - 1,
    y = math.random(screen.size.y) - 1,
    limiter = limiter or 1,
    screen = screen,
    settings = settings,
  }
  setmetatable(o, Vector)
  if o.limiter < 0.1 then
    o.limiter = 1
  end
  o.dx = Vector.random_velocity(o.settings) / o.limiter
  o.dy = Vector.random_velocity(o.settings) / o.limiter
  return o
end

function Vector.__tostring(vec)
  local pts
  pts = sprintf("[%.1f,%.1f]", vec.x, vec.y)
  return pts
end

return Vector
