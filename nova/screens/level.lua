local manager = require 'manager'
local json = require 'libs.json'
local themit = require 'libs.themit'
local suit    = require 'libs.suit'

local CurrentLevel = {}

function CurrentLevel:enter()
    boogaloo = love.graphics.newFont("assets/bogaloo.ttf", 50)
    love.graphics.setFont(boogaloo)

    hits = 0
    misses = 0
    local fullpath = currentlevel
    local contents, size = love.filesystem.read(fullpath)

    if contents then
        meta = json.decode(contents)
    end
end

function CurrentLevel:update()
    mousepos()
end

function CurrentLevel:draw()
    startframe()

    love.graphics.clear(0.17, 0.17, 0.28)
    suit.draw()

    endframe()
end

return CurrentLevel