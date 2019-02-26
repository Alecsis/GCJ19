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
                local moved = false
                if tank.state == tank.states.movement then
                    -- check if a cell is matching the wanted location
                    for _, cell in pairs(tank.movement_cells) do
                        if cell.i == mouse.i and cell.j == mouse.j then
                            -- get the movement cost
                            local cost = map:get_cost(cell)
                            tank:move(mouse.i, mouse.j, cost)
                            moved =  true
                        end
                    end
                end
                tank:set_idle_state()
                if not moved then
                    tank.selected = false
                end
            end
        end
    end
end

function love.draw()
    -- center the map
    love.graphics.push()
    love.graphics.translate(map.offset.x, map.offset.y)
    local tile_size = map.tilesize
    
    if tank.state == tank.states.movement then
        -- draw reachable cells
        for _, cell in pairs(tank.movement_cells) do
            -- local ratio = cell.cost / tank.current_movement
            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.rectangle("fill", cell.i * tile_size - 1, cell.j * tile_size - 1, tile_size + 2, tile_size + 2)
            --love.graphics.print(cell.cost, cell.i * tile_size, cell.j * tile_size)
        end
    elseif tank.state == tank.states.fire then
        for i = 1, tank.range do
            love.graphics.setColor(1, 0, 0, 1)
            if tank.i + i < map.size then
                love.graphics.rectangle("fill", (tank.i + i) * tile_size - 1, tank.j * tile_size - 1, tile_size + 2, tile_size + 2)
            end
            if tank.i - i >= 0 then
                love.graphics.rectangle("fill", (tank.i - i) * tile_size - 1, tank.j * tile_size - 1, tile_size + 2, tile_size + 2)
            end
            if tank.j + i < map.size then
                love.graphics.rectangle("fill", tank.i * tile_size - 1, (tank.j + i) * tile_size - 1, tile_size + 2, tile_size + 2)
            end
            if tank.j - i >= 0 then
                love.graphics.rectangle("fill", tank.i * tile_size - 1, (tank.j - i) * tile_size - 1, tile_size + 2, tile_size + 2)
            end
        end
    end
    
    -- enlight hovered cell
    if mouse.i >= 0 and mouse.i < map.size and mouse.j >= 0 and mouse.j < map.size then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", mouse.i * map.tilesize - 1, mouse.j * map.tilesize - 1, map.tilesize + 2, map.tilesize + 2)
        if tank.state == tank.states.movement then
            -- draw path
            local path = nil
            for _, cell in pairs(tank.movement_cells) do
                if cell.i == mouse.i and cell.j == mouse.j then
                    path = cell
                    love.graphics.setColor(1, 0, 1, 1)
                    love.graphics.rectangle("fill", tank.i * tile_size - 1, tank.j * tile_size - 1, tile_size + 2, tile_size + 2)
                    break
                end
            end

            while path ~= nil do
                love.graphics.rectangle("fill", path.i * tile_size - 1, path.j * tile_size - 1, tile_size + 2, tile_size + 2)
                path = path.from
            end
        end
    end

    map:draw()

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