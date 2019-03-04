local function set_mouse_position(mouse, px, py)
    mouse.x = px
    mouse.y = py
end

local function FMouse()
    local mouse = {}

    mouse.x = 0
    mouse.y = 0
    mouse.clic = false
    mouse.pressed = false
    mouse.released = false
    mouse.old_pressed = false
    mouse.x_clic = 0
    mouse.y_clic = 0
    -- game specific attributes
    mouse.i = 0
    mouse.j = 0

    mouse.set_mouse_position = set_mouse_position

    return mouse
end

return FMouse
