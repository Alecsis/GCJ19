-- constructor function
local FScreen = require("src.screen")
local FMap = require("src.map")
local FMouse = require("src.mouse")
local FTank = require("src.tank")

local function update(game, dt)
    local mouse = game.mouse
    local map = game.map

    -- update gui
    game.ui_group:update(dt)

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
    if not mouse.pressed and mouse.old_pressed then mouse.released = true end

    -- Hover tiles
    if game.play_state == game.play_states.player_fire then
        assert(game.selected_unit ~= nil)
        local selected = game.selected_unit
        local fire_cells = selected.fire_pattern
        for _, pattern in pairs(fire_cells) do
            local cell_i = selected.i + pattern[1]
            local cell_j = selected.j + pattern[2]
            local from_i = selected.i
            local from_j = selected.j
            if mouse.i == cell_i and mouse.j == cell_j then
                selected.rot = math.atan2(cell_j - from_j, cell_i - from_i)
            end
        end
    end

    if mouse.clic then
        -- is the clic on the map ?
        if map:in_bounds(mouse.i, mouse.j) then
            if game.play_state == game.play_states.player then
                game:deselect_unit()
                -- if a unit was clicked, select it
                for _, tank in pairs(game.allied_tanks) do
                    if tank.i == mouse.i and tank.j == mouse.j then game:select_unit(tank) end
                end
            elseif game.play_state == game.play_states.player_movement then
                assert(game.selected_unit ~= nil)
                local selected = game.selected_unit
                local did_move = false
                -- check if a cell is matching the wanted location
                for _, cell in pairs(selected.movement_cells) do
                    local cell_i = cell.i
                    local cell_j = cell.j
                    if cell_i == mouse.i and cell_j == mouse.j then
                        did_move = true
                        -- get the movement cost
                        local cost = map:get_cost(cell)
                        selected:move(mouse.i, mouse.j, cost)
                        -- check victory
                        if cell_i == map.objectives[2][1] - 1 and cell_j == map.objectives[2][2] - 1 then love.event.quit() end
                        break
                    end
                end
                if did_move then
                    game:end_turn()
                else
                    game.play_state = game.play_states.player
                end
            elseif game.play_state == game.play_states.player_fire then
                assert(game.selected_unit ~= nil)
                local selected = game.selected_unit
                local fire_cells = selected.fire_pattern
                local did_fire = false
                for _, pattern in pairs(fire_cells) do
                    local cell_i = selected.i + pattern[1]
                    local cell_j = selected.j + pattern[2]
                    local from_i = selected.i
                    local from_j = selected.j
                    if mouse.i == cell_i and mouse.j == cell_j then
                        -- rotate tank
                        selected.rot = math.atan2(cell_j - from_j, cell_i - from_i)
                        -- find if an enemy is hit
                        for _, enemy_tank in pairs(game.enemies_tanks) do
                            if enemy_tank.i == cell_i and enemy_tank.j == cell_j then
                                did_fire = true
                                -- apply damages
                                enemy_tank:take_damages(1)
                                -- animation
                                if enemy_tank.current_health > 0 then
                                    enemy_tank:play_animation(enemy_tank.anim_types.hit)
                                else
                                    enemy_tank:play_animation(enemy_tank.anim_types.dead)
                                end
                                break
                            end
                        end

                    end
                end
                if did_fire then
                    -- fire animation
                    selected:play_animation(selected.anim_types.fire)
                    game:end_turn()
                else
                    game.play_state = game.play_states.player
                end
            end

        else
            -- game.play_state = game.play_states.idle
        end
    end

    for _, tank in pairs(game.enemies_tanks) do tank:update(dt) end
    for _, tank in pairs(game.allied_tanks) do tank:update(dt) end
end

local function draw(game)

    local padding = 1.5
    local map = game.map
    local mouse = game.mouse
    local tile_size = map.tilesize
    local selected = game.selected_unit

    -- center the map
    love.graphics.push()
    love.graphics.translate(map.offset.x, map.offset.y)

    -- render map
    game.map:draw()

    -- render tanks
    love.graphics.setColor(1, 1, 1, 1)
    for _, tank in pairs(game.enemies_tanks) do tank:draw() end
    for _, tank in pairs(game.allied_tanks) do tank:draw() end

    if game.play_state == game.play_states.player_movement then
        assert(game.selected_unit ~= nil)
        -- draw reachable cells
        for _, cell in pairs(selected.movement_cells) do
            love.graphics.setColor(0, 0.6, 0, 1)
            love.graphics.draw(
                game.cadre,
                cell.i * map.tilesize,
                cell.j * map.tilesize
            )
        end
    elseif game.play_state == game.play_states.player_fire then
        assert(game.selected_unit ~= nil)
        -- draw gun cells
        love.graphics.setColor(1, 0, 0, 0.2)
        for _, pattern in pairs(selected.fire_pattern) do
            local cell_i = selected.i + pattern[1]
            local cell_j = selected.j + pattern[2]
            love.graphics.setColor(0.7, 0, 0, 1)
            if cell_i >= 0 and cell_i < map.size and cell_j >= 0 and cell_j < map.size then
                local cell_id = game.map:get(cell_i + 1, cell_j + 1)
                if cell_id ~= game.map.tiletypes.water then
                    love.graphics.draw(
                        game.cadre,
                        cell_i * map.tilesize,
                        cell_j * map.tilesize
                    )
                end
            end
        end
    end

    -- hovered cell
    if mouse.i >= 0 and mouse.i < map.size and mouse.j >= 0 and mouse.j < map.size then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            game.cadre,
            mouse.i * map.tilesize,
            mouse.j * map.tilesize
        )
    end

    love.graphics.setColor(0, 0, 0)
    local size = map.size
    local to_x = size * map.tilesize
    local to_y = (size + 1 / 2) * map.tilesize
    love.graphics.rectangle("fill", 0, to_y, to_x, map.tilesize / 2)

    love.graphics.pop()

    -- render UI
    game.ui_group:draw()
end

local function distance(i1, j1, i2, j2) return math.abs(i1 - i2) + math.abs(j1 - j2) end

local function end_turn_button_callback(game, pstate) if pstate == "end" then game:end_turn() end end

local function move_button_callback(game, pstate)
    if pstate == "end" then
        if game.selected_unit ~= nil then game:show_move_grid() end
    end
end

local function fire_button_callback(game, pstate)
    if pstate == "end" then
        if game.selected_unit ~= nil then game:show_fire_grid() end
    end
end

local function end_turn(game)
    game:deselect_unit()
    game.play_state = game.play_states.enemies
    game:new_turn() -- TO REMOVE !!!!!!!!!!
end

local function new_turn(game)
    game.play_state = game.play_states.player
    for _, tank in pairs(game.enemies_tanks) do tank:new_turn() end
    for _, tank in pairs(game.allied_tanks) do tank:new_turn() end
end

local function show_move_grid(game) game.play_state = game.play_states.player_movement end

local function show_fire_grid(game) game.play_state = game.play_states.player_fire end

local function select_unit(game, punit)
    game.selected_unit = punit
    game.move_button:setVisible(true)
    game.fire_button:setVisible(true)
end

local function deselect_unit(game)
    game.selected_unit = nil
    game.move_button:setVisible(false)
    game.fire_button:setVisible(false)
end

local function FGame()
    local game = {}

    -- screen dimensions
    game.screen = FScreen(
        love.graphics.getWidth(),
        love.graphics.getHeight()
    )

    -- map construction
    game.map = FMap(game, game.screen)

    game.arrow = love.graphics.newImage("assets/arrows.png")

    -- mouse object
    game.mouse = FMouse()
    game.cadre = love.graphics.newImage("assets/UI_Tile.png")

    ------------ GAME STATE --------------
    game.play_states = {
        player = 1,
        ennemies = 2,
        player_movement = 3,
        player_fire = 4
    }
    game.play_state = game.play_states.player
    --------------------------------------

    --------------- TANKS ----------------
    local obj_grid = game.map.objects
    local tank_grid = game.map.tanks

    game.selected_unit = nil

    game.allied_tanks = {}
    game.enemies_tanks = {}

    for i = 1, #tank_grid do
        for j = 1, #tank_grid[i] do
            local tank_id = tank_grid[i][j]
            if tank_id == 1 then
                local ally_tank = FTank(1, j - 1, i - 1, game.map)
                ally_tank.rot = math.pi / 2
                table.insert(game.allied_tanks, ally_tank)
            elseif tank_id == 2 then
                local enemy_tank = FTank(2, j - 1, i - 1, game.map)
                enemy_tank.rot = -math.pi / 2
                table.insert(game.enemies_tanks, enemy_tank)
            end
        end
    end
    --------------------------------------

    game.show_move_grid = show_move_grid
    game.show_fire_grid = show_fire_grid
    game.end_turn = end_turn

    ----------------- UI -----------------
    local gui = require("src.gui")
    local font = love.graphics.getFont()
    game.ui_group = gui.newNode(0, 0)

    -- move button
    local move_button = gui.newButton(game.screen.w / 3, 50, 150, 50, "MOVE", font, {0, 1, 0})
    move_button:setEvent("pressed", move_button_callback, game)
    move_button_callback(game, "end")
    move_button:setImage(love.graphics.newImage("assets/UI_Button_Move.png"))
    game.ui_group:appendChild(move_button)
    game.move_button = move_button
    move_button:setVisible(false)

    -- fire button
    local fire_button = gui.newButton(game.screen.w / 2, 50, 150, 50, "FIRE", font, {1, 0, 0})
    fire_button:setEvent("pressed", fire_button_callback, game)
    fire_button:setImage(love.graphics.newImage("assets/UI_Button_Shot.png"))
    game.fire_button = fire_button
    game.ui_group:appendChild(fire_button)
    fire_button:setVisible(false)
    --------------------------------------

    -- interface methods
    game.update = update
    game.draw = draw
    game.distance = distance
    game.select_unit = select_unit
    game.deselect_unit = deselect_unit
    game.new_turn = new_turn
    game.end_turn = end_turn

    return game
end

return FGame
