local function draw(map)
    for i = 1, map.size do
        local y = (i - 1) * map.tilesize
        for j = 1, map.size do
            local x = (j - 1) * map.tilesize
            local id = map.grid[i][j]
            love.graphics.setColor(map.tilecolor[id])
            local padding = 1
            love.graphics.rectangle("fill", x + padding, y + padding, map.tilesize - 2 * padding, map.tilesize - 2 * padding)
            --love.graphics.setColor(0.2, 0.2, 0.2)
            --love.graphics.rectangle("line", x, y, map.tilesize, map.tilesize)
        end
    end
end

local function get(map, i, j)
    return map.grid[j][i]
end

local function is_cell_reachable(map, i, j, movement)
    local reachables = map:get_reachable_cells(i, j, movement)
    for _, cell in pairs(reachables) do
        if cell.i == i and cell.j == j then return true end
    end
    return false
end

local function get_cost(map, from_i, from_j, to_i, to_j)
    -- routine functions
    local w = map.size
    local h = map.size

    local function new_cell(id, i, j, cost)
        local myCell = {}
        myCell.id = id
        myCell.i = i
        myCell.j = j
        myCell.cost = cost
        myCell.adj = {}
        return myCell
    end

    local function get_id(i, j, w)
        return (j - 1) * w + i
    end

    local function add_to_explore(exploration, to_add)
        for _, explo in pairs(exploration) do
            if explo.i == to_add.i and explo.j == to_add.j then
                if to_add.movement > explo.movement then
                    explo.movement = to_add.movement
                end
                return
            end
        end
        table.insert(exploration, to_add)
    end

    local function dijkstra(graph, id_src, id_dst, visited, distances, predecessors)
        if id_src == id_dst then
            path = {}
            local pred = id_dst
            while pred ~= nil then
                
    end

    -- variables declaration
    local from_node = new_node(from_i, from_j)
    local node_lst = {}
    table.insert(node_lst, from_node)


    -- beginning of the algorithm


    while #node_lst > 0 do

    end

    return cost
end

local function compute_costs(map)
    local w = map.size
    local h = map.size

    local function new_cell(id, i, j, cost)
        local myCell = {}
        myCell.id = id
        myCell.i = i
        myCell.j = j
        myCell.cost = cost
        myCell.adj = {}
        return myCell
    end

    local function get_id(i, j, w)
        return (j - 1) * w + i
    end

    graph = {}

    -- build graph
    -- 1) populate graph with cells
    for j = 1, h do
        for i = 1, w do
            local id = w * (j - 1) + i
            local cost = map.tilemovement[map:get(i,j)]
            local myCell = new_cell(id, i, j, cost)
            graph[id] = myCell
        end
    end
    -- 2) add neighbours
    for j = 1, h do
        --local str = ""
        for i = 1, w do
            local myCell = graph[get_id(i, j, w)]
            if i > 1 then
                local left = graph[get_id(i - 1, j, w)]
                table.insert(myCell.adj, left)
            end
            if i < w then
                local right = graph[get_id(i + 1, j, w)]
                table.insert(myCell.adj, right)
            end
            if j > 1 then
                local top = graph[get_id(i, j - 1, w)]
                table.insert(myCell.adj, top)
            end
            if j < h then
                local bottom = graph[get_id(i, j + 1, w)]
                table.insert(myCell.adj, bottom)
            end
            --str = str .. #(myCell.adj) .. ", "
        end
        --print(str)
    end

    map.graph = graph
end

local function get_reachable_cells(map, i, j, movement)
    local w = map.size
    local h = map.size

    local function new_cell(id, i, j, cost)
        local myCell = {}
        myCell.id = id
        myCell.i = i
        myCell.j = j
        myCell.cost = cost
        myCell.adj = {}
        return myCell
    end

    local function get_id(i, j, w)
        return (j - 1) * w + i
    end

    local function add_to_explore(exploration, to_add)
        for _, explo in pairs(exploration) do
            if explo.i == to_add.i and explo.j == to_add.j then
                if to_add.movement > explo.movement then
                    explo.movement = to_add.movement
                end
                return
            end
        end
        table.insert(exploration, to_add)
    end

    -- cells to explore
    local exploration = {}

    -- reachable exploration
    local reachables = {}

    -- store first cell
    add_to_explore(exploration, new_cell(i, j, movement))

    while #exploration > 0 do
        -- defile exploration to explore
        local curr = exploration[1]
        local movement = curr.movement
        local i = curr.i
        local j = curr.j
        local id = map:get(i,j)
        local tilemovement = map.tilemovement[id]

        -- remove current cell
        table.remove(exploration, 1)

        if movement >= tilemovement then
            -- this cell is reachable
            table.insert(reachables, curr)
            -- add to exploration adjacent exploration
            if i > 0 then
                local cell = new_cell(i - 1, j, movement - tilemovement)
                add_to_explore(exploration, cell)
            end
            if i < map.size - 1 then
                local cell = new_cell(i + 1, j, movement - tilemovement)
                add_to_explore(exploration, cell)
            end
            if j > 0 then
                local cell = new_cell(i, j - 1, movement - tilemovement)
                add_to_explore(exploration, cell)
            end
            if j < map.size - 1 then
                local cell = new_cell(i, j + 1, movement - tilemovement)
                add_to_explore(exploration, cell)
            end
        end
    end

    return reachables
end

local function FMap(screen)
    local map = {}

    local mapprops = require("data.mapprops")
    local tileprops = require("data.tileprops")

    map.size = mapprops.mapsize
    map.tilesize = tileprops.tilesize
    map.totalsize = tileprops.tilesize * mapprops.mapsize
    map.tilecolor = tileprops.tilecolor
    map.tilemovement = tileprops.tilemovement

    map.grid = mapprops.level

    -- map construction
    --[[map.grid = {}
    for i = 1, map.size do
    map.grid[i] = {}
        local str = ""
        for j = 1, map.size do
            local id = math.random(1,3)
            map.grid[i][j] = id
            str = str .. id .. ", "
        end 
        print(str)
    end]]

    -- map screen offset
    map.offset = {}
    map.offset.x = (screen.w - map.totalsize) / 2
    map.offset.y = (screen.h - map.totalsize) / 2

    -- interface functions
    map.draw = draw
    map.get = get
    map.get_reachable_cells = get_reachable_cells
    map.is_cell_reachable = is_cell_reachable
    map.get_cost = get_cost
    map.compute_costs = compute_costs


    -- init fuction
    map.graph = {}
    map:compute_costs()

    return map
end

return FMap