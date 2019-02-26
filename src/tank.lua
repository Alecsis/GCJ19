local function draw(tank)
    local tile_size = tank.map.tilesize
    local offset = (tile_size + tank.size) / 4
    local x = tank.i * tile_size + tank.size / 2
    local y = tank.j * tile_size + tank.size / 2
    
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
    -- reset tank movement capacity
    tank.current_movement = tank.movement
    -- refresh reachable cells
    tank.movement_cells = tank.map:get_reachable_cells(tank.i, tank.j, tank.current_movement)
end

local function move(tank, pi, pj, pcost)
    -- relocate tank to given location
    tank.i = pi
    tank.j = pj
    -- update movement points
    tank.current_movement = tank.current_movement - pcost
    -- refresh reachable cells
    tank.movement_cells = tank.map:get_reachable_cells(tank.i, tank.j, tank.current_movement)
end

local function FTank(pi, pj, pmap)
    local tank = {}

    -- on grid position
    tank.i = pi
    tank.j = pj

    -- am I selected
    tank.selected = false

    -- map reference
    tank.map = pmap

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
    tank.movement_cells = pmap:get_reachable_cells(pi, pj, tank.current_movement)

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