local suit    = require 'libs.suit'
local manager = require 'manager'
local themit = require 'libs.themit'
local f = require 'libs.trans'

local SettingsPage = {}

local VolumeSlider = {
    value = 50,
    min = 0,
    max = 100
}

function SettingsPage:enter()
    self.ui = suit.new()
    themit("Button")
end

function SettingsPage:update()
    mousepos()

    suit.Slider(VolumeSlider, 100,100, 200,20)
    suit.Label(tostring(VolumeSlider.value), 300,100, 200,20)
end

function SettingsPage:draw()

end

return SettingsPage