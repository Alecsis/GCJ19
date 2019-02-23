function love.load()
    math.randomseed(os.time())

    -- screen dimensions
    screen = {}
    screen.w = love.graphics.getWidth()
    screen.h = love.graphics.getHeight()

    -- map construction
    local FMap = require("src.map")
    map = FMap(screen)

    -- mouse object
    mouse = {}
    mouse.x = love.mouse.getX()
    mouse.y = love.mouse.getY()
    mouse.clic = false
    mouse.pressed = false
    mouse.released = false
    mouse.old_pressed = false
    mouse.x_clic = 0
    mouse.y_clic = 0

    -- tank
    local FTank = require("src.tank")
    tank = FTank(math.random(0, map.size - 1), math.random(0, map.size - 1), map, mouse)

    -- ui
    gui = require("src.gui")
    local font = love.graphics.getFont()
    ui_group = gui.newNode(0, 0)

    -- new turn button
    local function btn_newturn_pressed(pState)
        if pState == "end" then
            tank:new_turn()
        end
    end
    local newturn_button = gui.newButton(screen.w / 3, 50, 150, 50, "NEW TURN", font, {1,1,1})
    newturn_button:setEvent("pressed", btn_newturn_pressed)
    ui_group:appendChild(newturn_button)

    -- move button
    local function move_button_pressed(pState)
        if pState == "end" then
            if tank.selected then
                tank:set_move_state()
            end
        end
    end
    local move_button = gui.newButton(screen.w / 2, 50, 150, 50, "MOVE", font, {1,1,1})
    move_button:setEvent("pressed", move_button_pressed)
    ui_group:appendChild(move_button)

    -- fire button
    local function fire_button_pressed(pState)
        if pState == "end" then
            if tank.selected then
                tank:set_fire_state()
            end
        end
    end
    local fire_button = gui.newButton(2 * screen.w / 3, 50, 150, 50, "FIRE", font, {1,1,1})
    fire_button:setEvent("pressed", fire_button_pressed)
    ui_group:appendChild(fire_button)
end

function love.update(dt)
    -- update gui
    ui_group:update(dt)

    -- update mouse position
    mouse.x = love.mouse.getX()
    mouse.y = love.mouse.getY()
    local i = math.floor((mouse.x - map.offset.x) / map.tilesize) 
    local j = math.floor((mouse.y - map.offset.y) / map.tilesize)
    --[[if i < 0 then i = 0 end
    if i >= map.size then i = map.size - 1 end
    if j < 0 then j = 0 end
    if j >= map.size then j = map.size - 1 end]]
    mouse.i = i
    mouse.j = j
    
    -- mouse routine
    mouse.old_pressed = mouse.pressed
    mouse.clic = false
    mouse.released = false
    mouse.pressed = love.mouse.isDown(1)
    if mouse.pressed and not mouse.old_pressed then
        mouse.clic = true
        mouse.x_clic = mouse.x
        mouse.y_clic = mouse.y
    end
    if not mouse.pressed and mouse.old_pressed then
        mouse.released = true
    end

    -- selected tank
    if mouse.clic then
        if mouse.i >= 0 and mouse.i < map.size and mouse.j >= 0 and mouse.j < map.size then
            if mouse.i == tank.i and mouse.j == tank.j then
                tank.selected = true
            else
                if tank.state == tank.states.movement then
                    local cost = map:get_cost(tank.i, tank.j, mouse.i, mouse.j)
                    if map:is_cell_reachable(mouse.i, mouse.j, tank.current_movement) then
                        tank:move(mouse.i, mouse.j)
                    end
                end
                tank.selected = false
                tank:set_idle_state()
            end
        end
    end
end

function love.draw()
    -- center the map
    love.graphics.push()
    love.graphics.translate(map.offset.x, map.offset.y)
    local tile_size = map.tilesize
    map:draw()

    if tank.state == tank.states.movement then
        local reachables = map:get_reachable_cells(tank.i, tank.j, tank.movement)
        -- draw reachable cells
        for _, cell in pairs(reachables) do
            love.graphics.setColor(0,1,1,1)
            love.graphics.rectangle("line", cell.i * tile_size, cell.j * tile_size, tile_size, tile_size)
        end
    end

    -- enlight hovered cell
    if mouse.i >= 0 and mouse.i < map.size and mouse.j >= 0 and mouse.j < map.size then
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", mouse.i * map.tilesize, mouse.j * map.tilesize, map.tilesize, map.tilesize)
    end

    tank:draw()

    love.graphics.pop()
    ui_group:draw()
end

function love.keypressed(k)
    if k == "escape" then
        love.event.quit()
    end
    if k == "m" then
        tank.state = tank.states.move
    end
    if k == "f" then
        tank.state = tank.states.fire
    end
    if k == "space" then
        tank:new_turn()
    end
end

function love.keyreleased(k)
end