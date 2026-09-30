local flux = require 'libs.flux'
local manager = require 'manager'


    
function love.load()
    love.window.setMode(608, 1000, {
        love.graphics.setDefaultFilter("nearest", "nearest"),
        love.window.setTitle("Demo")
    })

    boogaloo = love.graphics.newFont("assets/bogaloo.ttf")
    love.graphics.setFont(boogaloo)

    manager:hook()
    manager:enter(require 'screens.mainmenu')
end

function love.update(dt)
end

function love.draw()
    
end