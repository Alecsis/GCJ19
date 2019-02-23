function love.load()
    -- deltatime
    dt =  0
    -- gamestates
    gamestates = {
        menu = 1,
        play = 2,
    }
    gamestate = gamestates.play

    -- playstates
    playstates = {
        scout = 1,
        engines = 2,
        cannon = 3,
    }
    playstate = playstates.engines

    -- window dimensions
    screenWidth = love.graphics.getWidth()
    screenHeight = love.graphics.getHeight()

    initTanks()
    initUI()
    initMap()
end

function initMap()
    local tilewidth = 20
    local width = math.floor(screenWidth / tilewidth)
    local height = math.floor(screenHeight / tilewidth)
    local pxwidth = width * tilewidth
    local pxheight = height * tilewidth
    local data = {}
    tilestates = {
        hidden = 0,
        discovered = 1,
        inrange = 2,
    }
    for i = 1, height do
        data[i] = {}
        for j = 1, width do
            data[i][j] = tilestates.hidden
        end
    end
    map = {
        tilewidth = tilewidth,
        width = width,
        height = height,
        pxwidth = pxwidth,
        pxheight = pxheight,
        data = data,
    }
end

function initTanks()
    -- tank structure
    tankprops = {
        images = {
            frame = {
                img = love.graphics.newCanvas(),
                width = 50,
                height = 30,
            },
            cannon = {
                img = love.graphics.newCanvas(),
                width = 30,
                height = 5,
            }
        },
        states = {
            engines = {
                moving = 0,
                turning = 1,
            },
            cannon = {
                idle = 0,
                turning = 1,
                loading = 2,
                ready = 3,
            }
        }
    }
    -- tank instance
    tank = {
        x = screenWidth / 2,
        y = screenHeight / 2,
        imgframe = tankprops.images.frame.img,
        imgcannon = tankprops.images.cannon.img,
        w = 50,
        h = 30,
        engines = {
            state = tankprops.states.engines.moving,
            maxSpeed = 50, -- px / s
            power = 50, -- percentage
            rotSpeed = math.rad(180), -- rad / s
            rot = math.rad(-45),
            rotTarget = 0,
        },
        cannon = {
            state = tankprops.states.cannon.idle,
            maxPower = 100, -- damages
            power = 0, -- percentage
            rotSpeed = math.rad(180), -- rad / s
            rot = math.rad(-45),
            rotTarget = 0,
        },
        scout = {
            rotSpeed = math.rad(180), -- rad / s
            rot = math.rad(-45),
        }
    }
    love.graphics.setCanvas(tankprops.images.frame.img)
    love.graphics.setColor(0.05, 0.125, 0.25)
    love.graphics.rectangle('fill', 0, 0, tankprops.images.frame.width, tankprops.images.frame.height)
    love.graphics.setColor(0.2, 0.5, 1)
    love.graphics.rectangle('line', 0, 0, tankprops.images.frame.width, tankprops.images.frame.height)
    love.graphics.setCanvas()
    love.graphics.setCanvas(tankprops.images.cannon.img)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle('fill', 0, 0, tankprops.images.cannon.width, tankprops.images.cannon.height)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle('line', 0, 0, tankprops.images.cannon.width, tankprops.images.cannon.height)
    love.graphics.setCanvas()
end

function initUI()
    -- ui
    gui = require("gui")
    local font = love.graphics.getFont()
    
    uiGroupMenu = gui.newNode(0, 0)
    uiGroupPlay = gui.newNode(0, 0)

    -- menu group
    local function onPlayPress(pState)
        if pState == "end" then
            gamestate = gamestates.play
        end
    end
    local playButton = gui.newButton(screenWidth - 50, 50, 50, 50, "PLAY", font, {0.5, 1, 0.5})
    playButton:setEvent("pressed", onPlayPress)
    uiGroupMenu:appendChild(playButton)
    
    -- playgroup
    local function onMenuPress(pState)
        if pState == "end" then
            gamestate = gamestates.menu
        end
    end
    local menuButton = gui.newButton(screenWidth - 50, 50, 50, 50, "MENU", font, {1, 0.5, 0.5})
    menuButton:setEvent("pressed", onMenuPress)
    uiGroupPlay:appendChild(menuButton)

    local function onScoutPress(pState)
        if pState == "end" then
            playstate = playstates.scout
        end
    end
    local scoutButton = gui.newButton(50, 50, 50, 50, "SCOUT", font, {0.5, 0.5, 1})
    scoutButton:setEvent("pressed", onScoutPress)
    uiGroupPlay:appendChild(scoutButton)

    local function onEnginesPress(pState)
        if pState == "end" then
            playstate = playstates.engines
        end
    end
    local enginesButton = gui.newButton(125, 50, 50, 50, "ENGINES", font, {0.5, 0.5, 1})
    enginesButton:setEvent("pressed", onEnginesPress)
    uiGroupPlay:appendChild(enginesButton)

    local function onCannonPress(pState)
        if pState == "end" then
            playstate = playstates.cannon
        end
    end
    local cannonButton = gui.newButton(200, 50, 50, 50, "CANNON", font, {0.5, 0.5, 1})
    cannonButton:setEvent("pressed", onCannonPress)
    uiGroupPlay:appendChild(cannonButton)
end

function love.update(pdt)
    -- update global deltatime
    dt = pdt

    -- update properly according the current gamestate
    if gamestate == gamestates.menu then
        updateMenu()
    elseif gamestate == gamestates.play then
        updatePlay()
    end
end

function updateMenu()
    -- update gui
    uiGroupMenu:update(dt)
end

function updatePlay()
    -- update tank engines
    local eng = tank.engines
    if eng.state == tankprops.states.engines.moving then -- moving
        local dx = math.cos(eng.rot) * eng.maxSpeed * eng.power / 100 * dt
        local dy = math.sin(eng.rot) * eng.maxSpeed * eng.power / 100 * dt
        tank.x = tank.x + dx
        tank.y = tank.y + dy
    elseif eng.state == tankprops.states.engines.turning then -- turning
        local angle = eng.rot - eng.rotTarget
        -- modulo pi
        while angle > math.pi do
            angle = angle - 2 * math.pi
        end
        while angle < - math.pi do
            angle = angle + 2 * math.pi
        end
        local da = eng.rotSpeed * dt
        if math.abs(angle) <= da then
            eng.rot = eng.rotTarget
            eng.state = tankprops.states.engines.moving
        else
            if angle > 0 then
                eng.rot = eng.rot - da
            elseif angle < 0 then
                eng.rot = eng.rot + da
            end
        end
    end

    -- update tank cannon
    local cannon = tank.cannon
    if cannon.state == tankprops.states.cannon.idle then
        
    elseif cannon.state == tankprops.states.cannon.loading then

    elseif cannon.state == tankprops.states.cannon.ready then

    elseif cannon.state == tankprops.states.cannon.turning then
        local angle = cannon.rot - cannon.rotTarget
        -- modulo pi
        while angle > math.pi do
            angle = angle - 2 * math.pi
        end
        while angle < - math.pi do
            angle = angle + 2 * math.pi
        end
        local da = cannon.rotSpeed * dt
        if math.abs(angle) <= da then
            cannon.rot = cannon.rotTarget
            cannon.state = tankprops.states.cannon.idle
        else
            if angle > 0 then
                cannon.rot = cannon.rot - da
            elseif angle < 0 then
                cannon.rot = cannon.rot + da
            end
        end
    end

    -- update fog of war
    local viewrange = 3
    local rx = math.floor(tank.x / map.tilewidth + 0.5)
    local ry = math.floor(tank.y / map.tilewidth + 0.5)
    for i = rx - viewrange, rx + viewrange do
        for j = ry - viewrange, ry + viewrange do
            if i > 0 and i <= map.width and j > 0 and j <= map.height then
                map.data[j][i] = tilestates.inrange
            end
        end
    end

    -- update gui
    uiGroupPlay:update(dt)

    local mx, my = love.mouse.getPosition()
    local mouseRightDown = love.mouse.isDown(2)
    local mouseLeftDown = love.mouse.isDown(1)

    if playstate == playstates.engines then -- engines
        if mouseRightDown then
            local dx = mx - tank.x
            local dy = my - tank.y
            local angle = math.atan2(dy, dx)
            -- modulo pi
            while angle > math.pi do
                angle = angle - 2 * math.pi
            end
            while angle < - math.pi do
                angle = angle + 2 * math.pi
            end
            if angle ~= eng.rotTarget then
                eng.rotTarget = angle
                eng.state = tankprops.states.engines.turning
            end
        end
    elseif playstate == playstates.cannon then -- cannon
        if mouseRightDown then
            local dx = mx - tank.x
            local dy = my - tank.y
            local angle = math.atan2(dy, dx)
            -- modulo pi
            while angle > math.pi do
                angle = angle - 2 * math.pi
            end
            while angle < - math.pi do
                angle = angle + 2 * math.pi
            end
            if angle ~= cannon.rotTarget then
                cannon.rotTarget = angle
                cannon.state = tankprops.states.cannon.turning
            end
        end
    end
end

function love.draw()
    -- draw properly according the current gamestate
    if gamestate == gamestates.menu then
        drawMenu()
    elseif gamestate == gamestates.play then
        drawPlay()
    end
end

function drawMenu()
    -- draw gui
    uiGroupMenu:draw()
    love.graphics.print("menu")
end

function drawPlay()
    love.graphics.clear(0,0,0)

    love.graphics.print("playstate : " .. playstate)

    -- draw map
    for i = 1, map.width do
        local x = (i-1) * map.tilewidth
        for j = 1, map.height do
            local y = (j-1) * map.tilewidth
            love.graphics.setColor(0.2,0.2,0.2)
            love.graphics.rectangle("line", x, y, map.tilewidth, map.tilewidth)
        end
    end

    -- draw tank
    love.graphics.setColor(1,1,1)
    local props = tankprops
    love.graphics.draw(tank.imgframe, tank.x, tank.y, tank.engines.rot, 1, 1, props.images.frame.width / 2, props.images.frame.height / 2)
    love.graphics.draw(tank.imgcannon, tank.x, tank.y, tank.cannon.rot, 1, 1, props.images.cannon.width / 10, props.images.cannon.height / 2)

    -- render fog of war
    love.graphics.push('all')
    for i = 1, map.width do
        local x = (i-1) * map.tilewidth
        for j = 1, map.height do
            local y = (j-1) * map.tilewidth
            local tilestate = map.data[j][i]
            if tilestate == tilestates.hidden then
                love.graphics.setColor(0, 0, 0)
                love.graphics.rectangle("fill", x, y, map.tilewidth, map.tilewidth)
            elseif tilestate == tilestates.discovered then
                love.graphics.setColor(0.2, 0.2, 0.3)
                love.graphics.rectangle("fill", x, y, map.tilewidth, map.tilewidth)
            elseif tilestate == tilestates.inrange then
                --love.graphics.setColor(1, 1, 1)
                --love.graphics.rectangle("fill", x, y, map.tilewidth, map.tilewidth)
            end
        end
    end
    love.graphics.pop()

    -- draw ui
    uiGroupPlay:draw()
end

function love.keypressed(k)
    -- if escape is pressed, quit the game
    if k == 'escape' then
        love.event.quit()
    end
    
    -- react properly according the current gamestate
    if gamestate == gamestates.menu then
        keypressedMenu(k)
    elseif gamestate == gamestates.play then
        keypressedPlay(k)
    end
end

function keypressedMenu(k)
end

function keypressedPlay(k)
end