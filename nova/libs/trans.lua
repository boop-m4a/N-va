local suit = require 'libs.suit'

local viewW, viewH = 608, 1080
local viewX, viewY = 0, 0

function love.resize(w, h)
    viewX = (w - viewW) / 2
    viewY = (h - viewH) / 2
end

function mousepos()
    local realMouseX, realMouseY = love.mouse.getPosition()

    local gameMouseX = realMouseX - viewX
    local gameMouseY = realMouseY - viewY

    suit.updateMouse(gameMouseX, gameMouseY)
end

function startframe()
    love.graphics.setScissor(viewX, viewY, viewW, viewH)

    love.graphics.push()
    love.graphics.translate(viewX, viewY)
end

function endframe()
    love.graphics.pop()
    love.graphics.setScissor()
end