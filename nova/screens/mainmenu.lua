local suit    = require 'libs.suit'
local manager = require 'manager'
local levelselect = require 'screens.levelselect'
local themit = require 'libs.themit'
local f = require 'libs.trans'
local settings = require 'screens.settings'

local MainMenu = {}



function MainMenu:enter()
    themit("Button")
    bogaloo = love.graphics.newFont("assets/bogaloo.ttf", 50)
    love.graphics.setFont(bogaloo)
    suit.theme.font = bogaloo
    
    self.logo = love.graphics.newImage("assets/logo.png")
    button = love.graphics.newImage("assets/button.png")
end

function MainMenu:update(dt)
    mousepos()

    suit.layout:reset(154, 100)
    if suit.Button("Level Select", 0, 550, 508, 100).hit then
        manager:enter(levelselect)
    end

    if suit.Button("Settings", 0, 665, 508, 100).hit then
        manager:enter(settings)
    end

    if suit.Button("Quit", 0, 780, 508, 100).hit then
        love.event.quit()
    end
end

function MainMenu:draw()
    startframe()

    love.graphics.clear(0.17, 0.17, 0.28)
    love.graphics.draw(self.logo, 103, 250, 0, 1.5, 1.5)
    suit.draw()

    endframe()
end

return MainMenu