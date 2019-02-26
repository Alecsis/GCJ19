local game

function love.load()
    math.randomseed(os.time())
    local FGame = require("src.game")
    game = FGame()
end

function love.update(dt) game:update(dt) end

function love.draw() game:draw() end

function love.keypressed(k)
    if k == "escape" then love.event.quit() end
    if k == "m" then player_tank:set_move_state() end
    if k == "f" then player_tank:set_fire_state() end
    if k == "space" then player_tank:new_turn() end
end

function love.keyreleased(k) end
