local suit    = require 'libs.suit'
local manager = require 'manager'
local levelselect = require 'screens.levelselect'

local MainMenu = {}

function MainMenu:enter()
    self.logo = love.graphics.newImage("assets/logo.png")
end

function MainMenu:update(dt)
    suit.layout:reset(154, 100)
    if suit.Button("Level Select", suit.layout:row(300, 100)).hit then
        manager:enter(levelselect)
    end
end

function MainMenu:draw()
    love.graphics.clear(0.3, 0.3, 0.34)
    love.graphics.draw(self.logo, 0, 0)
    suit.draw()
end

return MainMenu