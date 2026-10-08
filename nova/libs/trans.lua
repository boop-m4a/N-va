local suit = require 'libs.suit'

local viewW, viewH = 608, 1080
local viewX, viewY = 0, 0

-- Re-centres the 608x1080 play area in the window. Called on resize AND every
-- frame (cheap), so it's right even if no resize event fires at startup.
local function recalc()
    local w, h = love.graphics.getDimensions()
    viewX = math.floor((w - viewW) / 2)
    viewY = math.floor((h - viewH) / 2)
end

function love.resize(w, h)
    recalc()
end

-- Mouse position in game coordinates (0..608, 0..1080), no side effects.
function gamemouse()
    recalc()
    local realMouseX, realMouseY = love.mouse.getPosition()
    return realMouseX - viewX, realMouseY - viewY
end

function mousepos()
    local gameMouseX, gameMouseY = gamemouse()
    suit.updateMouse(gameMouseX, gameMouseY)
end

function startframe()
    recalc()
    love.graphics.setScissor(viewX, viewY, viewW, viewH)

    love.graphics.push()
    love.graphics.translate(viewX, viewY)
end

function endframe()
    love.graphics.pop()
    love.graphics.setScissor()
end
