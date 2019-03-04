-- render map to the screen
local function draw(map)
    love.graphics.setColor(1, 1, 1)
    for i = 1, map.size do
        local y = (i - 1) * map.tilesize
        for j = 1, map.size do
            local x = (j - 1) * map.tilesize
            local id = map.grid[i][j]
            --[[love.graphics.setColor(map.tilecolor[id])
      local padding = 1.5
      love.graphics.rectangle("fill", x + padding, y + padding, map.tilesize - 2 * padding, map.tilesize - 2 * padding)
      --love.graphics.setColor(0.2, 0.2, 0.2)
      --love.graphics.rectangle("line", x, y, map.tilesize, map.tilesize)
      ]] --
            love.graphics.draw(map.imgs.tiles[id], x, y)
        end
    end
    -- draw objects
    for i = 1, map.size do
        local y = (i - 1) * map.tilesize
        for j = 1, map.size do
            local x = (j - 1) * map.tilesize
            local id = map.obj_grid[i][j]
            if id ~= 0 then love.graphics.draw(map.imgs.objects[id], x, y) end
        end
    end
end

-- returns the cell corresponding to given location
local function get(map, i, j)
    assert(
        i > 0 and i <= map.size and j > 0 and j <= map.size,
        "I or J not in bounds : " .. i .. " , " .. j
    )
    return map.grid[j][i]
end

local function get_obj(map, i, j)
    assert(
        i > 0 and i <= map.size and j > 0 and j <= map.size,
        "I or J not in bounds : " .. i .. " , " .. j
    )
    return map.obj_grid[j][i]
end

-- returns if the cell is solid
local function is_solid(map, i, j)
    local solid_tile = map.solid[map:get(i, j)]
    local solid_obj = map.solid_obj[map:get_obj(i, j)]
    return solid_tile or solid_obj
end

-- computes the exploration algorithm to know if a cell is reachable
-- from a starting position with a given movement
local function is_cell_reachable(map, i, j, movement)
    local reachables = map:get_reachable_cells(i, j, movement)
    for _, cell in pairs(reachables) do if cell.i == i and cell.j == j then return true end end
    return false
end

-- data structure to storing a path for the exploration algorithm
local function new_cell(i, j, cost, from) -- TODO: remove movement
    local myCell = {}
    myCell.i = i
    myCell.j = j
    myCell.cost = cost
    myCell.from = from
    return myCell
end

local function add_to_explore(exploration, to_add)
    -- check if the tile is already in the exploration list
    for _, explo in pairs(exploration) do
        if explo.i == to_add.i and explo.j == to_add.j then
            -- in that case, if to_add has more movement points left
            if to_add.cost < explo.cost then
                -- replace current cell by to_add cell
                explo.from = to_add.from
                explo.cost = to_add.cost
            end
            return
        end
    end
    table.insert(exploration, to_add)
end

local function get_cost(map, cell)
    -- get current cell cost
    local i = cell.i
    local j = cell.j
    local id = map:get(i + 1, j + 1)
    local cost = map.tilemovement[id]

    -- if the cell has a parent, make it recursive
    if cell.from ~= nil then cost = cost + map:get_cost(cell.from) end

    return cost
end

-- return tilemovement correspoding to a given location
local function get_tilemovement(map, pi, pj)
    local id = map:get(pi + 1, pj + 1)
    return map.tilemovement[id]
end

local function entity_in_cell(map, pi, pj)
    local count = 0
    for _, tank in pairs(map.game.allied_tanks) do if tank.dead == false and tank.i == pi and tank.j == pj then count = count + 1 end end
    for _, tank in pairs(map.game.enemies_tanks) do if tank.dead == false  and tank.i == pi and tank.j == pj then count = count + 1 end end
    return count
end

-- gather all reachables cells from a certain position 
-- with respect to a given movement
local function get_reachable_cells(map, pi, pj, pmovement)
    local w = map.size
    local h = map.size

    -- cells to explore
    local exploration = {}

    -- reachable exploration
    local reachables = {new_cell(pi, pj, 0, nil)}

    -- store adjacent cells

    if pi > 0 then
        local cell = new_cell(pi - 1, pj, map:get_tilemovement(pi - 1, pj), nil)
        add_to_explore(exploration, cell)
    end
    if pi < map.size - 1 then
        local cell = new_cell(pi + 1, pj, map:get_tilemovement(pi + 1, pj), nil)
        add_to_explore(exploration, cell)
    end
    if pj > 0 then
        local cell = new_cell(pi, pj - 1, map:get_tilemovement(pi, pj - 1), nil)
        add_to_explore(exploration, cell)
    end
    if pj < map.size - 1 then
        local cell = new_cell(pi, pj + 1, map:get_tilemovement(pi, pj + 1), nil)
        add_to_explore(exploration, cell)
    end

    while #exploration > 0 do
        ---print(#exploration, #reachables)
        -- defile exploration to explore
        local curr = exploration[1]
        local i = curr.i
        local j = curr.j

        -- how many movement points are left
        local movement = curr.movement

        -- get current cell movement cost
        local total_cost = map:get_tilemovement(i, j)
        if curr.from ~= nil then total_cost = total_cost + curr.from.cost end

        -- remove current cell from the to-explore list
        table.remove(exploration, 1)

        if pmovement >= total_cost then
            -- this cell is reachable
            -- check if there is another path on this cell
            local already_explored = false
            for _, reach in pairs(reachables) do
                if reach.i == curr.i and reach.j == curr.j then
                    -- in that case, if the current path has more movement points left
                    if curr.cost < reach.cost then
                        -- replace old path with the current path
                        reach.movement = curr.movement
                        reach.from = curr.from
                        reach.cost = curr.cost
                    else
                        -- if the old path is better, don't run the algorithm again for this cell
                        already_explored = true
                    end
                    break
                end
            end
            -- only add path if it is new
            if not already_explored and not map:is_solid(i + 1, j + 1) and map:entity_in_cell(i, j) == 0 then
                table.insert(reachables, curr)

                -- add to exploration adjacent exploration
                if i > 0 then
                    local adj_cost = map:get_tilemovement(i - 1, j)
                    if total_cost + adj_cost <= pmovement then
                        local cell = new_cell(i - 1, j, total_cost + adj_cost, curr)
                        add_to_explore(exploration, cell)
                    end
                end
                if i < map.size - 1 then
                    local adj_cost = map:get_tilemovement(i + 1, j)
                    if total_cost + adj_cost <= pmovement then
                        local cell = new_cell(i + 1, j, total_cost + adj_cost, curr)
                        add_to_explore(exploration, cell)
                    end
                end
                if j > 0 then
                    local adj_cost = map:get_tilemovement(i, j - 1)
                    if total_cost + adj_cost <= pmovement then
                        local cell = new_cell(i, j - 1, total_cost + adj_cost, curr)
                        add_to_explore(exploration, cell)
                    end
                end
                if j < map.size - 1 then
                    local adj_cost = map:get_tilemovement(i, j + 1)
                    if total_cost + adj_cost <= pmovement then
                        local cell = new_cell(i, j + 1, total_cost + adj_cost, curr)
                        add_to_explore(exploration, cell)
                    end
                end
            end
        end
    end

    return reachables
end

local function get_tank_vision(map, tank)
    local pattern = {}
    pattern[1] = {
        {0, 0},
        {1, 0},
        {2, 0},
        {3, 0},
        {1, 1},
        {2, 1},
        {1, -1},
        {2, -1},
    }
    pattern[2] = {{0, 0}, {0, 1}, {1, 0}, {1, 1}, {2, 1}, {2, 1}, {2, 2},}
    pattern[3] = {
        {0, 0},
        {0, 1},
        {0, 2},
        {0, 3},
        {1, 1},
        {1, 2},
        {-1, 1},
        {-1, 2},
    }
    pattern[4] = {
        {-0, 0},
        {-0, 1},
        {-1, 0},
        {-1, 1},
        {-2, 1},
        {-2, 1},
        {-2, 2},
    }
    pattern[5] = {
        {-0, 0},
        {-1, 0},
        {-2, 0},
        {-3, 0},
        {-1, 1},
        {-2, 1},
        {-1, -1},
        {-2, -1},
    }
    pattern[6] = {
        {-0, -0},
        {-0, -1},
        {-1, -0},
        {-1, -1},
        {-2, -1},
        {-2, -1},
        {-2, -2},
    }
    pattern[7] = {
        {0, 0},
        {0, -1},
        {0, -2},
        {0, -3},
        {1, -1},
        {1, -2},
        {-1, -1},
        {-1, -2},
    }
    pattern[8] = {
        {0, -0},
        {0, -1},
        {1, -0},
        {1, -1},
        {2, -1},
        {2, -1},
        {2, -2},
    }
    return pattern[tank.direction]

end

local function in_bounds(map, pi, pj) return pi >= 0 and pi < map.size and pj >= 0 and pj < map.size end

local function FMap(game, screen)
    local map = {}

    local mapprops = require("data.mapprops")
    local tileprops = require("data.tileprops")
    local objprops = require("data.objprops")

    map.size = mapprops.mapsize
    map.tilesize = tileprops.tilesize
    map.totalsize = tileprops.tilesize * mapprops.mapsize
    map.tilecolor = tileprops.tilecolor
    map.tilemovement = tileprops.tilemovement
    map.solid = tileprops.solid
    map.solid_obj = objprops.solid
    map.tiletypes = tileprops.tiletypes
    map.game = game

    map.grid = mapprops.level.terrain
    map.tanks = mapprops.level.tanks
    map.objects = mapprops.level.objects

    map.objectives = {}

    map.obj_grid = {}
    for j = 1, #map.grid do
        map.obj_grid[j] = {}
        for i = 1, #map.grid[j] do
            local obj_id = map.objects[j][i]
            map.obj_grid[j][i] = obj_id
            if obj_id == 2 then
                map.objectives[1] = {i, j}
            elseif obj_id == 3 then
                map.objectives[2] = {i, j}
            end
        end
    end

    map.imgs = {}
    map.imgs.tiles = {}
    map.imgs.objects = {}
    for id, path in pairs(tileprops.imgpaths) do map.imgs.tiles[id] = love.graphics.newImage(path) end
    for id, path in pairs(objprops.imgpaths) do map.imgs.objects[id] = love.graphics.newImage(path) end

    -- map screen offset
    map.offset = {}
    map.offset.x = (screen.w - map.totalsize) / 2
    map.offset.y = (screen.h - map.totalsize) / 2

    -- interface functions
    map.draw = draw
    map.get = get
    map.get_obj = get_obj
    map.is_solid = is_solid
    map.get_reachable_cells = get_reachable_cells
    map.is_cell_reachable = is_cell_reachable
    map.get_tilemovement = get_tilemovement
    map.get_cost = get_cost
    map.get_tank_vision = get_tank_vision
    map.in_bounds = in_bounds
    map.entity_in_cell = entity_in_cell

    return map
end

return FMap
