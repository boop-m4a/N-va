local flux = require 'libs.flux'
local manager = require 'manager'

    
function love.load()
    love.window.setMode(608, 1080, {
        love.graphics.setDefaultFilter("nearest", "nearest"),
        love.window.setTitle("Demo")
    })
    love.window.setFullscreen(true, "desktop")
    vw, vh = 608, 1080
    gameCanvas = love.graphics.newCanvas(vw, vh)

    manager:hook()
    manager:enter(require 'screens.mainmenu')
end

function love.update(dt)
end

function love.draw()
    startframe()
    endframe()
end