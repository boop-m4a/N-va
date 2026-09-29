local flux = require 'libs.flux'
local manager = require 'manager'


    
function love.load()
    love.window.setMode(608, 1080, {
        love.graphics.setDefaultFilter("nearest", "nearest"),
        love.window.setTitle("Demo")
    })

    manager:hook()
    manager:enter(require 'screens.mainmenu')
end

function love.update(dt)
end

function love.draw()
end