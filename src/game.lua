-- constructor function
local FScreen = require("src.screen")
local FMap = require("src.map")
local FMouse = require("src.mouse")
local FTank = require("src.tank")

local function end_turn(game)
    game:deselect_unit()
    game.play_state = game.play_states.enemies
    game.end_turn_tmr = 0.5
end

local function new_turn(game)
    game.play_state = game.play_states.player
    for _, tank in pairs(game.enemies_tanks) do tank:new_turn() end
    for _, tank in pairs(game.allied_tanks) do tank:new_turn() end
end

local function show_move_grid(game)
    assert(game.selected_unit ~= nil)
    game.play_state = game.play_states.player_movement
    game.selected_unit:refresh_reachable()
end

local function show_fire_grid(game) game.play_state = game.play_states.player_fire end

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

local function new_game_button_callback(game, pstate)
    if pstate == "end" then game.game_state = game.game_states.play end
end

local function new_game(game)

    -- map construction
    game.map = FMap(game, game.screen)
    local mapwidth = game.map.tilesize * game.map.size
    local mapheight = game.map.tilesize * game.map.size

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
                ally_tank:set_blink(true)
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
    game.play_ui_group = gui.newNode(game.map.offset.x, 0)
    game.menu_ui_group = gui.newNode(0, 0)

    -- play game button
    local play_game_button = gui.newButton(
        game.screen.w * 0.5,
        game.screen.h * 0.52,
        150,
        50,
        "NEW_TURN",
        font,
        {0, 1, 0}
    )
    play_game_button:setImage(love.graphics.newImage("assets/start_game_btn.png"))
    game.menu_ui_group:appendChild(play_game_button)
    play_game_button:setEvent("pressed", new_game_button_callback, game)
    game.play_game_button = play_game_button

    -- blank button
    local new_turn_button = gui.newButton(mapwidth / 2, 32, 150, 50, "NEW_TURN", font, {0, 1, 0})
    new_turn_button:setImage(love.graphics.newImage("assets/new_btn_end_turn.png"))
    game.play_ui_group:appendChild(new_turn_button)
    game.new_turn_button = new_turn_button

    -- move button
    local move_button = gui.newButton(mapwidth / 4, 32, 150, 50, "MOVE", font, {0, 1, 0})
    move_button:setEvent("pressed", move_button_callback, game)
    move_button:setImage(love.graphics.newImage("assets/UI_Button_Move2.png"))
    game.play_ui_group:appendChild(move_button)
    game.move_button = move_button
    move_button:setVisible(false)

    -- fire button
    local fire_button = gui.newButton(3 * mapwidth / 4, 32, 150, 50, "FIRE", font, {1, 0, 0})
    fire_button:setEvent("pressed", fire_button_callback, game)
    fire_button:setImage(love.graphics.newImage("assets/UI_Button_Shot2.png"))
    game.fire_button = fire_button
    game.play_ui_group:appendChild(fire_button)
    fire_button:setVisible(false)
    --------------------------------------
end

local function update(game, dt)

    -- mouse routine
    local mouse = game.mouse
    mouse.x = love.mouse.getX()
    mouse.y = love.mouse.getY()
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

    -- game states
    if game.game_state == game.game_states.splash then
        game.menu_ui_group:update(dt)
        if love.keyboard.isDown('space') or love.keyboard.isDown('return') then
            game:new_game()
            game.game_state = game.game_states.play
        end
    elseif game.game_state == game.game_states.win then
        --game.menu_ui_group:update(dt)
        if love.keyboard.isDown('space') or love.keyboard.isDown('return') then
            game:new_game()
            game.game_state = game.game_states.play
        end
    elseif game.game_state == game.game_states.lose then
        --game.menu_ui_group:update(dt)
        if love.keyboard.isDown('space') or love.keyboard.isDown('return') then
            game:new_game()
            game.game_state = game.game_states.play
        end
    elseif game.game_state == game.game_states.play then
        -- update gui
        game.play_ui_group:update(dt)

        local map = game.map
        map:update(dt)
        local i = math.floor((mouse.x - map.offset.x) / map.tilesize)
        local j = math.floor((mouse.y - map.offset.y) / map.tilesize)
        mouse.i = i
        mouse.j = j

        -- Hover tiles
        if game.play_state == game.play_states.player_movement then
            assert(game.selected_unit ~= nil)
            local selected = game.selected_unit
            for _, cell in pairs(selected.movement_cells) do
                local cell_i = cell.i
                local cell_j = cell.j
                local from_i = selected.i
                local from_j = selected.j
                if mouse.i == cell_i and mouse.j == cell_j then
                    selected.rot = math.atan2(cell_j - from_j, cell_i - from_i)
                end
            end
        elseif game.play_state == game.play_states.player_fire then
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

        if game.play_state == game.play_states.enemies then
            game.end_turn_tmr = game.end_turn_tmr - dt
            if game.end_turn_tmr <= 0 then
                game:ai_logic()
                if game.game_state ~= game.game_states.lose then
                    game:new_turn()
                    for _, tank in pairs(game.allied_tanks) do tank:set_blink(true) end
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
                        if tank.i == mouse.i and tank.j == mouse.j and tank.will_die == false then game:select_unit(tank) end
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
                            -- sleep the tank
                            selected.did_play = true
                            selected:set_blink(false)
                            -- check victory
                            if cell_i == map.objectives[2][1] - 1 and cell_j == map.objectives[2][2] - 1 then game.game_state = game.game_states.win end
                            -- refresh cells for each tank
                            for _2, tank2 in pairs(game.allied_tanks) do tank2:refresh_reachable() end
                            for _2, tank2 in pairs(game.enemies_tanks) do tank2:refresh_reachable() end
                            break
                        end
                    end
                    -- check if the turn is over if tank did move
                    if did_move then
                        -- did we move all units
                        local all_unit_played = true
                        for _, tank in pairs(game.allied_tanks) do
                            if tank.did_play == false and tank.will_die == false then
                                all_unit_played = false
                                break
                            end
                        end
                        -- all unit played : next turn
                        if all_unit_played == true then
                            game:end_turn()
                        else
                            -- if an unit hasn't played, go back to player state
                            game:deselect_unit()
                            game.play_state = game.play_states.player
                        end
                    else
                        -- if we didn't move, go back to player state
                        game:deselect_unit()
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
                                    -- sleep the tank
                                    selected.did_play = true
                                    selected:set_blink(false)
                                    -- apply damages
                                    enemy_tank:take_damages(1)
                                    for _, tank2 in pairs(game.enemies_tanks) do tank2:refresh_reachable() end
                                    for _, tank2 in pairs(game.allied_tanks) do tank2:refresh_reachable() end
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
                        -- did we move all units
                        local all_unit_played = true
                        for _, tank in pairs(game.allied_tanks) do
                            if tank.did_play == false and tank.will_die == false then
                                all_unit_played = false
                                break
                            end
                        end
                        -- all unit played : next turn
                        if all_unit_played == true then
                            game:end_turn()
                        else
                            -- if an unit hasn't played, go back to player state
                            game.play_state = game.play_states.player
                            game:deselect_unit()
                        end
                    else
                        game.play_state = game.play_states.player
                        game:deselect_unit()
                    end
                end

            else
                -- game.play_state = game.play_states.idle
            end
        end

        -- update /remove tanks
        for i = #game.enemies_tanks, 1, -1 do
            local tank = game.enemies_tanks[i]
            tank:update(dt)

            if tank.dead and tank.anim_over then
                table.remove(game.enemies_tanks, i)
                if #game.enemies_tanks == 0 then game.game_state = game.game_states.win end
            end
        end

        for i = #game.allied_tanks, 1, -1 do
            local tank = game.allied_tanks[i]
            tank:update(dt)

            if tank.dead and tank.anim_over then
                table.remove(game.allied_tanks, i)
                if #game.allied_tanks == 0 then game.game_state = game.game_states.lose end
            end
        end
    end

end

local function draw(game)
    love.graphics.setColor(1, 1, 1)
    if game.game_state == game.game_states.splash then
        love.graphics.draw(game.titlescreen)
        love.graphics.setFont(game.font)
        love.graphics.printf(
            "Press space to play",
            0,
            game.screen.h - game.fontsize - 10,
            game.screen.w,
            "center"
        )
        love.graphics.setFont(game.font_title)
        love.graphics.printf(
            "- CheckTanks -",
            0,
            game.screen.w / 2 - game.fontsize / 2,
            game.screen.w,
            "center"
        )
        game.menu_ui_group:draw()
    elseif game.game_state == game.game_states.win then
        love.graphics.draw(game.gameover)
        love.graphics.setFont(game.font)
        love.graphics.printf(
            "Press space to play",
            0,
            game.screen.h - game.fontsize - 10,
            game.screen.w,
            "center"
        )
        love.graphics.printf(
            "You won !",
            0,
            game.fontsize / 2,
            game.screen.w,
            "center"
        )
        --game.menu_ui_group:draw()
    elseif game.game_state == game.game_states.lose then
        love.graphics.draw(game.gameover)
        love.graphics.setFont(game.font)
        love.graphics.printf(
            "Press space to play",
            0,
            game.screen.h - game.fontsize - 10,
            game.screen.w,
            "center"
        )
        love.graphics.printf(
            "You lost !",
            0,
            game.fontsize / 2,
            game.screen.w,
            "center"
        )
        --game.menu_ui_group:draw()
    elseif game.game_state == game.game_states.play then

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

        -- draw info around idle units
        love.graphics.setColor(0.8, 1, 0.6)
        for _, tank in pairs(game.allied_tanks) do
            if tank.did_play == false then
                if tank.blink == true and tank.blink_state == true then
                    love.graphics.draw(
                        game.cadre,
                        tank.i * map.tilesize,
                        tank.j * map.tilesize
                    )
                end
            end
        end

        -- draw selector around selected unit
        if game.selected_unit ~= nil then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                game.cadre,
                game.selected_unit.i * map.tilesize,
                game.selected_unit.j * map.tilesize
            )
        end

        -- translation off
        love.graphics.pop()

        -- render UI
        game.play_ui_group:draw()
    end
end

local function distance(i1, j1, i2, j2) return math.abs(i1 - i2) + math.abs(j1 - j2) end
local function ai_logic(game)
    -- player camp to defend
    local obj_i = game.map.objectives[1][1] - 1
    local obj_j = game.map.objectives[1][2] - 1
    -- loop over all enemies tanks to update them
    for _, tank in pairs(game.enemies_tanks) do
        if tank.will_die == false then
            local player_in_range = nil
            local fire_cells = tank.fire_pattern
            for _, pattern in pairs(fire_cells) do
                local cell_i = tank.i + pattern[1]
                local cell_j = tank.j + pattern[2]
                local from_i = tank.i
                local from_j = tank.j
                for _, ally_tank in pairs(game.allied_tanks) do
                    if ally_tank.i == cell_i and ally_tank.j == cell_j then
                        player_in_range = ally_tank
                        tank.rot = math.atan2(cell_j - from_j, cell_i - from_i)
                        break
                    end
                end
            end
            if player_in_range ~= nil then
                tank:play_animation(tank.anim_types.fire)
                -- apply damages
                player_in_range:take_damages(1)
                for _, tank2 in pairs(game.enemies_tanks) do tank2:refresh_reachable() end
                for _, tank2 in pairs(game.allied_tanks) do tank2:refresh_reachable() end
                -- animation
                if player_in_range.current_health > 0 then
                    player_in_range:play_animation(player_in_range.anim_types.hit)
                else
                    player_in_range:play_animation(player_in_range.anim_types.dead)
                end

            else
                local movement_cells = tank.movement_cells
                if #movement_cells > 0 then
                    -- find the cell that is closest to the objective
                    local closer_cell = movement_cells[1]
                    local closer_dst2 = math.pow(closer_cell.i - obj_i, 2) + math.pow(closer_cell.j - obj_j, 2)
                    -- loop over reachable cells
                    for _, cell in pairs(movement_cells) do
                        local dst2 = math.pow(cell.i - obj_i, 2) + math.pow(cell.j - obj_j, 2)
                        -- if it's closer, store it
                        if dst2 < closer_dst2 then
                            closer_dst2 = dst2
                            closer_cell = cell
                        end
                    end
                    -- jump to it
                    tank:move(closer_cell.i, closer_cell.j, 0)
                end
                -- check lose condition
                if tank.i == obj_i and tank.j == obj_j then game.game_state = game.game_states.lose end
                -- refresh cells for each tank
                for _2, tank2 in pairs(game.enemies_tanks) do tank2:refresh_reachable() end
            end
        end
    end
end

local function select_unit(game, punit)
    game.selected_unit = punit
    if punit.did_play == false then
        local enemy_in_range = false
        local fire_cells = punit.fire_pattern
        for _, pattern in pairs(fire_cells) do
            local cell_i = punit.i + pattern[1]
            local cell_j = punit.j + pattern[2]
            for _, tank in pairs(game.enemies_tanks) do
                if tank.i == cell_i and tank.j == cell_j then
                    enemy_in_range = true
                    break
                end
            end
        end
        if enemy_in_range then
            game.play_state = game.play_states.player_fire
        else
            game.play_state = game.play_states.player_movement
        end
        game.move_button:setVisible(true)
        game.fire_button:setVisible(true)
    end
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

    -- mouse object
    game.mouse = FMouse()
    game.cadre = love.graphics.newImage("assets/UI_Tile.png")

    -- game states
    game.game_states = {splash = 1, play = 2, win = 3, lose = 4,}
    game.game_state = game.game_states.splash

    -- game playstates
    game.play_states = {
        player = 1,
        ennemies = 2,
        player_movement = 3,
        player_fire = 4
    }
    game.play_state = game.play_states.player

    -- textures
    -- screens
    game.titlescreen = love.graphics.newImage("assets/Titlescreen.png")
    game.gameover = love.graphics.newImage("assets/GAMEOVER.png")
    -- font
    game.fontsize = 30
    game.font = love.graphics.newFont("assets/Minecraft.ttf", game.fontsize)
    game.font_title = love.graphics.newFont("assets/Minecraft.ttf", 1.5 * game.fontsize)
    love.graphics.setFont(game.font)

    -- constructor
    game.new_game = new_game
    game:new_game()

    -- interface methods
    game.update = update
    game.draw = draw
    game.distance = distance
    game.select_unit = select_unit
    game.deselect_unit = deselect_unit
    game.new_turn = new_turn
    game.end_turn = end_turn
    game.ai_logic = ai_logic

    return game
end

return FGame
