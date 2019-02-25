local function draw(tank)
    local tile_size = tank.map.tilesize
    local offset = (tile_size + tank.size) / 4
    local x = tank.i * tile_size + tank.size / 2
    local y = tank.j * tile_size + tank.size / 2

    if tank.state == tank.states.move then
        -- draw reachable cells
        for _, cell in pairs(tank.reachables) do
            love.graphics.setColor(0,1,1,1)
            love.graphics.rectangle("line", cell.i * tile_size, cell.j * tile_size, tile_size, tile_size)
        end
    elseif tank.state == tank.states.fire then
        for i = 1, tank.range do
            love.graphics.setColor(1,0,0,1)
            if tank.i + i < tank.map.size then
                love.graphics.rectangle("line", (tank.i + i) * tile_size, tank.j * tile_size, tile_size, tile_size)
            end
            if tank.i - i >= 0 then
                love.graphics.rectangle("line", (tank.i - i) * tile_size, tank.j * tile_size, tile_size, tile_size)
            end
            if tank.j + i < tank.map.size then
                love.graphics.rectangle("line", tank.i * tile_size, (tank.j + i) * tile_size, tile_size, tile_size)
            end
            if tank.j - i >= 0 then
                love.graphics.rectangle("line", tank.i * tile_size, (tank.j - i) * tile_size, tile_size, tile_size)
            end
        end
    end
    
    -- draw tank
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("fill", x, y, tank.size, tank.size)
    if tank.selected then
        love.graphics.setColor(0.8,0.8,0.8)
        love.graphics.rectangle("line", x, y, tank.size, tank.size)
    end
end

local function update(tank, dt)
end

local function set_move_state(tank)
    tank.state = tank.states.movement
end

local function set_idle_state(tank)
    tank.state = tank.states.idle
end

local function set_fire_state(tank)
    tank.state = tank.states.fire
end

local function new_turn(tank)
    tank:set_idle_state()
    tank.current_movement = tank.movement
end

local function move(tank, pi, pj, pcost)
    tank.i = pi
    tank.j = pj
    tank.current_movement = tank.current_movement - pcost
end

local function FTank(i, j, map)
    local tank = {}

    -- on grid position
    tank.i = i
    tank.j = j

    -- am I selected
    tank.selected = false

    -- map reference
    tank.map = map

    -- size of image
    tank.size = map.tilesize / 2

    -- load some properties
    local tankprops = require("data.tankprops")
    tank.range = tankprops.range -- fire range
    tank.movement = tankprops.movement -- movement range
    tank.current_movement = tank.movement
    tank.states = tankprops.states -- states
    tank.state = tank.states.idle

    -- cells reachable
    --tank.reachables = get_reachable_cells(tank)

    -- interface functions
    tank.set_move_state = set_move_state
    tank.set_idle_state = set_idle_state
    tank.set_fire_state = set_fire_state
    tank.draw = draw
    tank.new_turn = new_turn
    tank.move = move

    return tank
end

return FTank