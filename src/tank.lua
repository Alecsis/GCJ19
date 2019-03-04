local function draw(tank)
    if tank.dead then return end

    local tile_size = tank.map.tilesize
    local offset = (tile_size + tank.size) / 4
    local x = tank.i * tile_size + tile_size / 2
    local y = tank.j * tile_size + tile_size / 2

    love.graphics.setColor(1, 1, 1)
    -- love.graphics.draw(tank.img, x, y, (tank.direction - 1) * math.pi / 2, 1, 1, tank.size / 2, tank.size / 2)
    -- love.graphics.draw(tank.img, x, y, tank.rot, 1, 1, tank.size / 2, tank.size / 2)
    local quad = tank.quads[tank.current_anim][tank.frame]

    --[[if tank.blink == true then
        if tank.blink_state == true then
            love.graphics.setBlendMode("add", "alphamultiply")
            local a = 0.2
            love.graphics.setColor(a,a,a)
        else
            love.graphics.setColor(1, 1, 1)
        end
    end]]
    love.graphics.draw(
        tank.img,
        quad,
        x,
        y,
        tank.rot + math.pi / 2,
        1,
        1,
        tank.size / 2,
        tank.size / 2
    )
    -- love.graphics.setBlendMode("alpha")
end

local function update(tank, dt)
    local anim = tank.animations[tank.current_anim]
    tank.anim_timer = tank.anim_timer + dt
    if tank.anim_timer > anim.speed then
        -- if tank.current_anim == tank.anim_types.fire then print(anim.frames[tank.frame]) end
        tank.frame = tank.frame + 1
        tank.anim_timer = 0
        if tank.frame > #anim.frames then
            if tank.current_anim == tank.anim_types.dead then tank.dead = true end
            tank.frame = 1
            tank.current_anim = anim.next
            tank.anim_over = true
        else
            tank.anim_over = false
        end
    end
    -- update blink
    if tank.blink == true then
        tank.blink_tmr = tank.blink_tmr + dt
        if tank.blink_state == false then
            if tank.blink_tmr > tank.blink_speed * (1 - tank.blink_ratio) then
                tank.blink_state = not tank.blink_state
                tank.blink_tmr = 0
            end

        else
            if tank.blink_tmr > tank.blink_speed * tank.blink_ratio then
                tank.blink_state = not tank.blink_state
                tank.blink_tmr = 0
            end
        end
    end
end

local function take_damages(tank, pdmg)
    tank.current_health = tank.current_health - pdmg
    tank.health_ratio = tank.current_health / tank.health
end

local function new_turn(tank)
    -- reset tank movement capacity
    tank.current_movement = tank.movement

    -- refresh reachable cells
    tank:refresh_reachable()

    tank.did_play = false
end

local function refresh_reachable(tank)
    -- refresh reachable cells
    tank.movement_cells = tank.map:get_reachable_cells(tank.i, tank.j, tank.current_movement)
end

local function move(tank, pi, pj, pcost)
    if tank.i == pi and tank.j == pj then return end

    -- rotate tank
    local angle = math.atan2(pj - tank.j, pi - tank.i)
    tank.rot = angle

    -- relocate tank to given location
    tank.i = pi
    tank.j = pj

    -- update movement points
    tank.current_movement = tank.current_movement - pcost

    -- refresh reachable cells
    tank.movement_cells = tank.map:get_reachable_cells(tank.i, tank.j, tank.current_movement)
end

local function play_animation(tank, panim_type)
    tank.frame = 1
    tank.current_anim = panim_type
    tank.anim_timer = 0
end

local function set_blink(tank, pblink)
    if pblink ~= tank.blink then
        tank.blink = pblink
        tank.blink_tmr = 0
        tank.blink_state = false
    end
end

local function FTank(pteam, pi, pj, pmap)
    local tank = {}
    -- team
    tank.team = pteam

    -- on grid position
    tank.i = pi
    tank.j = pj

    -- map reference
    tank.map = pmap

    -- alive or dead flag
    tank.dead = false

    -- load some properties
    local tankprops = require("data.tankprops")
    tank.range = tankprops.range -- fire range
    tank.movement = tankprops.movement -- movement range
    tank.current_movement = tank.movement
    tank.health = tankprops.health
    tank.current_health = tank.health
    tank.health_ratio = tank.current_health / tank.health
    tank.target_path = nil
    tank.img = love.graphics.newImage(tankprops.imgs[pteam])
    tank.rot = 0
    tank.vision = tankprops.vision
    tank.direction = 1
    tank.did_play = false
    -- blink if tank hasn't play
    tank.blink = false
    tank.blink_tmr = 0
    tank.blink_speed = 1
    tank.blink_ratio = 1 / 2
    tank.blink_state = true

    -- animations
    tank.anim_types = tankprops.anim_types
    tank.animations = tankprops.animations
    tank.current_anim = tank.anim_types.idle
    tank.frame = 1
    tank.anim_timer = 0
    tank.anim_over = false
    tank.quads = {}
    local spritesheet = tankprops.spritesheet
    for anim_type, anim in pairs(tank.animations) do
        local quads = {}
        for i = 1, #anim.frames do
            local frame = anim.frames[i]
            local row = math.floor(frame / spritesheet.width)
            local col = frame - row * spritesheet.width
            local x = (col - 1) * spritesheet.frame_width
            local y = (row) * spritesheet.frame_height
            quads[i] = love.graphics.newQuad(
                x,
                y,
                spritesheet.frame_width,
                spritesheet.frame_height,
                tank.img:getDimensions()
            )
        end
        tank.quads[anim_type] = quads
    end

    -- size
    tank.size = spritesheet.frame_width

    -- cells reachable
    tank.movement_cells = pmap:get_reachable_cells(pi, pj, tank.current_movement)
    tank.fire_pattern = tankprops.fire_pattern

    -- interface functions
    tank.draw = draw
    tank.update = update
    tank.new_turn = new_turn
    tank.move = move
    tank.take_damages = take_damages
    tank.play_animation = play_animation
    tank.refresh_reachable = refresh_reachable
    tank.set_blink = set_blink

    return tank
end

return FTank
