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

    -- selected player_tank
    if mouse.clic then
        if mouse.i >= 0 and mouse.i < map.size and mouse.j >= 0 and mouse.j < map.size then
            if mouse.i == player_tank.i and mouse.j == player_tank.j then
                player_tank.selected = true
            else
                local moved = false
                if player_tank.state == player_tank.states.movement then
                    -- check if a cell is matching the wanted location
                    for _, cell in pairs(player_tank.movement_cells) do
                        if cell.i == mouse.i and cell.j == mouse.j then
                            -- get the movement cost
                            local cost = map:get_cost(cell)
                            player_tank:move(mouse.i, mouse.j, cost)
                            moved = true
                        end
                    end
                end
                player_tank:set_idle_state()
                if not moved then player_tank.selected = false end
            end
        end
    end
end

local function draw(game)
    local map = game.map
    local mouse = game.mouse
    local player_tank = game.player_tank
    -- center the map
    love.graphics.push()
    love.graphics.translate(map.offset.x, map.offset.y)
    local tile_size = map.tilesize

    if player_tank.state == player_tank.states.movement then
        -- draw reachable cells
        for _, cell in pairs(player_tank.movement_cells) do
            -- local ratio = cell.cost / player_tank.current_movement
            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.rectangle(
                "fill",
                cell.i * tile_size - 1,
                cell.j * tile_size - 1,
                tile_size + 2,
                tile_size + 2
            )
            -- love.graphics.print(cell.cost, cell.i * tile_size, cell.j * tile_size)
        end
    elseif player_tank.state == player_tank.states.fire then
        for i = 1, player_tank.range do
            love.graphics.setColor(1, 0, 0, 1)
            if player_tank.i + i < map.size then
                love.graphics.rectangle(
                    "fill",
                    (player_tank.i + i) * tile_size - 1,
                    player_tank.j * tile_size - 1,
                    tile_size + 2,
                    tile_size + 2
                )
            end
            if player_tank.i - i >= 0 then
                love.graphics.rectangle(
                    "fill",
                    (player_tank.i - i) * tile_size - 1,
                    player_tank.j * tile_size - 1,
                    tile_size + 2,
                    tile_size + 2
                )
            end
            if player_tank.j + i < map.size then
                love.graphics.rectangle(
                    "fill",
                    player_tank.i * tile_size - 1,
                    (player_tank.j + i) * tile_size - 1,
                    tile_size + 2,
                    tile_size + 2
                )
            end
            if player_tank.j - i >= 0 then
                love.graphics.rectangle(
                    "fill",
                    player_tank.i * tile_size - 1,
                    (player_tank.j - i) * tile_size - 1,
                    tile_size + 2,
                    tile_size + 2
                )
            end
        end
    end

    -- enlight hovered cell
    if mouse.i >= 0 and mouse.i < map.size and mouse.j >= 0 and mouse.j < map.size then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle(
            "fill",
            mouse.i * map.tilesize - 1,
            mouse.j * map.tilesize - 1,
            map.tilesize + 2,
            map.tilesize + 2
        )
        if player_tank.state == player_tank.states.movement then
            -- draw path
            local path = nil
            for _, cell in pairs(player_tank.movement_cells) do
                if cell.i == mouse.i and cell.j == mouse.j then
                    path = cell
                    love.graphics.setColor(1, 0, 1, 1)
                    love.graphics.rectangle(
                        "fill",
                        player_tank.i * tile_size - 1,
                        player_tank.j * tile_size - 1,
                        tile_size + 2,
                        tile_size + 2
                    )
                    break
                end
            end
            while path ~= nil do
                love.graphics.rectangle(
                    "fill",
                    path.i * tile_size - 1,
                    path.j * tile_size - 1,
                    tile_size + 2,
                    tile_size + 2
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

local function new_turn_button_callback(game, pstate) if pstate == "end" then game.player_tank:new_turn() end end

local function move_button_callback(game, pstate)
    if pstate == "end" then
        if game.player_tank.selected then game.player_tank:set_move_state() end
    end
end

local function fire_button_callback(game, pstate)
    if pstate == "end" then
        if game.player_tank.selected then game.player_tank:set_fire_state() end
    end
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

    ---------------- TANKS ----------------
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
    local nb_enemies = 5
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

    ----------------- UI -----------------
    local gui = require("src.gui")
    local font = love.graphics.getFont()
    game.ui_group = gui.newNode(0, 0)

    -- new turn button
    local newturn_button = gui.newButton(game.screen.w / 3, 50, 150, 50, "NEW TURN", font, {1, 1, 1})
    newturn_button:setEvent("pressed", new_turn_button_callback, game)
    game.ui_group:appendChild(newturn_button)

    -- move button
    local move_button = gui.newButton(game.screen.w / 2, 50, 150, 50, "MOVE", font, {1, 1, 1})
    move_button:setEvent("pressed", move_button_callback, game)
    move_button_callback(game, "end")
    game.ui_group:appendChild(move_button)

    -- fire button
    local fire_button = gui.newButton(2 * game.screen.w / 3, 50, 150, 50, "FIRE", font, {1, 1, 1})
    fire_button:setEvent("pressed", fire_button_callback, game)
    game.ui_group:appendChild(fire_button)
    --------------------------------------

    -- interface methods
    game.update = update
    game.draw = draw

    return game
end

return FGame
