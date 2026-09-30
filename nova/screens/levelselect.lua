local suit    = require 'libs.suit'
local manager = require 'manager'
local level = require 'screens.level'
local json = require 'libs.json'

local LevelSelect = {}

local level_list = {}

function LevelSelect:enter()
    self.ui = suit.new()

    self.level_list = {}

    local files = love.filesystem.getDirectoryItems("levels")

     for i, filename in ipairs(files) do
        if filename:match("%.json$") then
            table.insert(self.level_list, filename)
        end
    end
end

function LevelSelect:update()
    suit.layout:reset(154, 100)
    if suit.Button("start level", suit.layout:row(300, 100)).hit then
        manager:enter(level)
    end

    for i, filename in ipairs(self.level_list) do
        if suit.Button(filename, suit.layout:row(300, 40)).hit then
            currentlevel = filename 
            manager:enter(level)
        end
    end
end

function LevelSelect:draw()
    love.graphics.clear(0.3, 0.3, 0.34)    
    suit.draw()
end

return LevelSelect