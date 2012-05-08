local Screen = {
  size = { x = display.contentWidth - (2 * display.screenOriginX),
           y = display.contentHeight - (2 * display.screenOriginY) },
  origin = { x = display.screenOriginX,
             y = display.screenOriginY },
}
Screen.center = Util.vec_add(Screen.origin, Util.vec_scale(Screen.size, 0.5))

Screen.topleft = Screen.origin
Screen.bottomright = Util.vec_add(Screen.origin, Screen.size)
Screen.left = Screen.topleft.x
Screen.top = Screen.topleft.y
Screen.right = Screen.bottomright.x
Screen.bottom = Screen.bottomright.y

function Screen.new(group)
  inset = inset or 0
  local o = display.newGroup()
  o.x = Screen.origin.x
  o.y = Screen.origin.y
  group:insert(o)
  for idx, value in pairs(Screen) do
    if type(value) ~= 'function' then
      o[idx] = value
    end
  end
  return o
end

return Screen
