local game

function love.load()
    love.graphics.setDefaultFilter("nearest")
    love.graphics.setLineWidth(1.5)
    --love.window.setTitle("CheckTanks GCJ19 v0.0.1 by Alecsis and Kowee")
    math.randomseed(os.time())
    local FGame = require("src.game")
    game = FGame()
end

function love.update(dt) game:update(dt) end

function love.draw() game:draw() end

function love.keypressed(k)
    if k == "escape" then love.event.quit() end
    --[[if k == "m" then game:show_move_grid() end
    if k == "f" then game:show_fire_grid() end
    if k == "space" then game:end_turn() end
    ]]
end

function love.keyreleased(k) end
