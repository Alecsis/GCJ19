local function update(game, dt)
    local mouse = game.mouse
    local map = game.map
    local player_tank = game.player_tank

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

    if mouse.clic then
        -- is the clic on the map ?
        if mouse.i >= 0 and mouse.i < map.size and mouse.j >= 0 and mouse.j < map.size then
            if game.play_state == game.play_states.idle then

            elseif game.play_state == game.play_states.movement then
                -- check if a cell is matching the wanted location
                for _, cell in pairs(player_tank.movement_cells) do
                    if cell.i == mouse.i and cell.j == mouse.j then
                        -- get the movement cost
                        local cost = map:get_cost(cell)
                        player_tank:move(mouse.i, mouse.j, cost)
                        game.play_state = game.play_states.fire
                        break
                    end
                end
            elseif game.play_state == game.play_states.fire then
                local fire_cells = {}
                for _, pattern in pairs(player_tank.fire_pattern) do
                    local cell_i = player_tank.i + pattern[1]
                    local cell_j = player_tank.j + pattern[2]
                    if mouse.i == cell_i and mouse.j == cell_j then
                        for _, enemy_tank in pairs(game.enemies_tanks) do
                            if enemy_tank.i == cell_i and enemy_tank.j == cell_j then
                                enemy_tank:take_damages(1)
                                game.play_state = game.play_states.movement
                                break
                            end
                        end

                    end
                end
            end

        else
            --game.play_state = game.play_states.idle
        end
    end
end

local function draw(game)
    local padding = 1.5
    local map = game.map
    local mouse = game.mouse
    local player_tank = game.player_tank
    -- center the map
    love.graphics.push()
    love.graphics.translate(map.offset.x, map.offset.y)
    local tile_size = map.tilesize

    if game.play_state == game.play_states.movement then
        -- draw reachable cells
        for _, cell in pairs(player_tank.movement_cells) do
            -- local ratio = cell.cost / player_tank.current_movement
            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.rectangle(
                "fill",
                cell.i * tile_size - padding,
                cell.j * tile_size - padding,
                tile_size + 2 * padding,
                tile_size + 2 * padding
            )
            -- love.graphics.print(cell.cost, cell.i * tile_size, cell.j * tile_size)
        end
    elseif game.play_state == game.play_states.fire then
        love.graphics.setColor(1, 0, 0, 1)
        for _, pattern in pairs(player_tank.fire_pattern) do
            local cell_i = player_tank.i + pattern[1]
            local cell_j = player_tank.j + pattern[2]
            if cell_i >= 0 and cell_i < map.size and cell_j >= 0 and cell_j < map.size then
                love.graphics.rectangle(
                    "fill",
                    (player_tank.i + pattern[1]) * tile_size - padding,
                    (player_tank.j + pattern[2]) * tile_size - padding,
                    tile_size + 2 * padding,
                    tile_size + 2 * padding
                )
            end
        end
    end

    -- enlight hovered cell
    if mouse.i >= 0 and mouse.i < map.size and mouse.j >= 0 and mouse.j < map.size then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle(
            "fill",
            mouse.i * map.tilesize - padding,
            mouse.j * map.tilesize - padding,
            map.tilesize + 2 * padding,
            map.tilesize + 2 * padding
        )
        if game.play_state == game.play_states.movement then
            -- draw path
            local path = nil
            for _, cell in pairs(player_tank.movement_cells) do
                if cell.i == mouse.i and cell.j == mouse.j then
                    path = cell
                    love.graphics.setColor(1, 0, 1, 1)
                    love.graphics.rectangle(
                        "fill",
                        player_tank.i * tile_size - padding,
                        player_tank.j * tile_size - padding,
                        tile_size + 2 * padding,
                        tile_size + 2 * padding
                    )
                    break
                end
            end
            while path ~= nil do
                love.graphics.rectangle(
                    "fill",
                    path.i * tile_size - padding,
                    path.j * tile_size - padding,
                    tile_size + 2 * padding,
                    tile_size + 2 * padding
                )
                path = path.from
            end
        end
    end

    -- render map
    game.map:draw()

    -- render enemies tanks
    for _, enemy_tank in pairs(game.enemies_tanks) do
        love.graphics.setColor(1, 1, 1, 1)
        enemy_tank:draw()
    end

    -- render player's tank
    player_tank:draw()

    love.graphics.pop()

    -- render UI
    game.ui_group:draw()
end

local function end_turn_button_callback(game, pstate) if pstate == "end" then game:end_turn() end end

local function move_button_callback(game, pstate) if pstate == "end" then game:show_move_grid() end end

local function fire_button_callback(game, pstate) if pstate == "end" then game:show_fire_grid() end end

local function end_turn(game)
    game.player_tank:new_turn()
    game:show_move_grid()
end

local function show_move_grid(game)
    game.player_tank.selected = true
    game.play_state = game.play_states.movement
end

local function show_fire_grid(game)
    game.player_tank.selected = true
    game.play_state = game.play_states.fire
end

local function FGame()
    local game = {}

    -- constructor function
    local FScreen = require("src.screen")
    local FMap = require("src.map")
    local FMouse = require("src.mouse")
    local FTank = require("src.tank")

    -- screen dimensions
    game.screen = FScreen(
        love.graphics.getWidth(),
        love.graphics.getHeight()
    )

    -- map construction
    game.map = FMap(game.screen)

    -- mouse object
    game.mouse = FMouse()

    ------------ GAME STATE --------------
    game.play_states = {move = 1, fire = 2, idle = 3,}
    game.play_state = game.play_states.idle
    --------------------------------------

    --------------- TANKS ----------------
    -- player's tank
    game.player_tank = FTank(
        1,
        math.random(0, game.map.size - 1),
        math.random(0, game.map.size - 1),
        game.map
    )
    game.player_tank.selected = true

    -- enemies
    game.enemies_tanks = {}
    local nb_enemies = 3
    for i = 1, nb_enemies do
        enemy_tank = FTank(
            2,
            math.random(0, game.map.size - 1),
            math.random(0, game.map.size - 1),
            game.map
        )
        table.insert(game.enemies_tanks, enemy_tank)
    end
    --------------------------------------

    game.show_move_grid = show_move_grid
    game.show_fire_grid = show_fire_grid
    game.end_turn = end_turn

    ----------------- UI -----------------
    local gui = require("src.gui")
    local font = love.graphics.getFont()
    game.ui_group = gui.newNode(0, 0)

    -- new turn button
    local end_turn_button = gui.newButton(game.screen.w * 2 / 3, 50, 150, 50, "END TURN", font, {1, 1, 1})
    end_turn_button:setEvent("pressed", end_turn_button_callback, game)
    game.ui_group:appendChild(end_turn_button)

    -- move button
    local move_button = gui.newButton(game.screen.w / 3, 50, 150, 50, "MOVE", font, {0, 1, 0})
    move_button:setEvent("pressed", move_button_callback, game)
    move_button_callback(game, "end")
    game.ui_group:appendChild(move_button)

    -- fire button
    local fire_button = gui.newButton(game.screen.w / 2, 50, 150, 50, "FIRE", font, {1, 0, 0})
    fire_button:setEvent("pressed", fire_button_callback, game)
    game.ui_group:appendChild(fire_button)
    --------------------------------------

    -- interface methods
    game.update = update
    game.draw = draw

    return game
end

return FGame
