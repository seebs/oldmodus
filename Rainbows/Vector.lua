local Vector = {}

function Vector.move(vector)
end

function Vector.random_velocity(params)
  local d = math.random(params.VELOCITY_MAX - params.VELOCITY_MIN) + params.VELOCITY_MIN
  if math.random(2) == 2 then
    d = d * -1
  end
  return d
end

function Vector.move_vec(vec, toward)
  local bounce_x, bounce_y, bounce_theta = false, false, false
  local accel = vec.params.TOUCH_ACCEL or 2

  if toward then
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
  if vec.x < vec.screen.left then
    bounce_x = true
    vec.x = vec.screen.left + (vec.screen.left - vec.x)
  elseif vec.x > vec.screen.right then
    bounce_x = true
    vec.x = vec.screen.right - (vec.x - vec.screen.right)
  end

  vec.y = vec.y + vec.dy
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

  return bounce_x or bounce_y
end

function Vector.coerce(vec, member, big)
  local v = vec[member]
  local max_v = vec.params.VELOCITY_MAX / (vec.limiter or 1)
  local min_v = vec.params.VELOCITY_MIN / (vec.limiter or 1)
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

function Vector.new(screen, params, limiter)
  local o = {
    x = math.random(screen.size.x) - 1,
    y = math.random(screen.size.y) - 1,
    limiter = limiter or 1,
    screen = screen,
    params = params,
  }
  if o.limiter < 0.1 then
    o.limiter = 1
  end
  o.dx = Vector.random_velocity(o.params) / o.limiter
  o.dy = Vector.random_velocity(o.params) / o.limiter
  o.move = Vector.move_vec
  return o
end

return Vector
