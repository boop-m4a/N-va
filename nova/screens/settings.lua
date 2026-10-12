local suit    = require 'libs.suit'
local manager = require 'manager'
local themit = require 'libs.themit'
local f = require 'libs.trans'

local SettingsPage = {}

local VolumeSlider = {
    value = 50,
    max = 100
}

function SettingsPage:enter()
    self.ui = suit.new()
    themit("Button")
    back = love.graphics.newImage("assets/button.png")
end

function SettingsPage:update()
    mousepos()

    if love.keyboard.isDown("escape") then
            manager:enter(require 'screens.mainmenu')
    end

    suit.Label("Volume:", 40, 320)
    suit.Slider(VolumeSlider, 40,400, 200,20)
    suit.Label(tostring(VolumeSlider.value), 200,400, 200,20)
end

function SettingsPage:draw()
    startframe()

    love.graphics.clear(0.17, 0.17, 0.28)
    love.graphics.draw(back, -150, 320, 0, 1.2, 1.2)
    suit.draw()
    
    endframe()
end

return SettingsPage