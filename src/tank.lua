local function draw(tank)
    if tank.dead then return end

    local tile_size = tank.map.tilesize
    local offset = (tile_size + tank.size) / 4
    local x = tank.i * tile_size + tank.size / 2
    local y = tank.j * tile_size + tank.size / 2

    -- draw tank
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", x, y, tank.size, tank.size)

    if tank.team == 1 then
        love.graphics.setColor(0, 1, 0)
    elseif tank.team == 2 then
        love.graphics.setColor(1, 0, 0)
    elseif tank.team == 3 then
        love.graphics.setColor(0, 0, 1)
    end

    love.graphics.rectangle(
        "fill",
        x,
        y + tank.size * (1 - tank.health_ratio),
        tank.size,
        tank.size * tank.health_ratio
    )

    if tank.selected then
        love.graphics.setColor(0.5, 0.5, 0.5)
    else
        love.graphics.setColor(0, 0, 0)
    end
    love.graphics.rectangle("line", x, y, tank.size, tank.size)

end

local function update(tank, dt) end

local function take_damages(tank, pdmg)
    tank.current_health = tank.current_health - pdmg
    tank.health_ratio = tank.current_health / tank.health
    if tank.current_health <= 0 then tank.dead = true end
end

local function new_turn(tank)
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

local function FTank(pteam, pi, pj, pmap)
    local tank = {}
    -- team
    tank.team = pteam

    -- on grid position
    tank.i = pi
    tank.j = pj

    -- am I selected
    tank.selected = false

    -- map reference
    tank.map = pmap

    -- size of image
    tank.size = pmap.tilesize / 2

    -- alive or dead flag
    tank.dead = false

    -- load some properties
    local tankprops = require("data.tankprops")
    tank.range = tankprops.range -- fire range
    tank.movement = tankprops.movement -- movement range
    tank.current_movement = tank.movement
    tank.health = tankprops.health
    tank.current_health = math.random(1, tank.health)
    tank.health_ratio = tank.current_health / tank.health

    -- cells reachable
    tank.movement_cells = pmap:get_reachable_cells(pi, pj, tank.current_movement)
    tank.fire_pattern = {
        {2, 0}, 
        {-2, 0}, 
        {0, 2}, 
        {0, -2}, 
        {3, 0}, 
        {-3, 0}, 
        {0, 3}, 
        {0, -3}, 
    }

    -- interface functions
    tank.draw = draw
    tank.new_turn = new_turn
    tank.move = move
    tank.take_damages = take_damages

    return tank
end

return FTank
