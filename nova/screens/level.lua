local manager = require 'manager'
local json = require 'libs.json'

local CurrentLevel = {}

function CurrentLevel:enter()
    boogaloo = love.graphics.newFont("assets/bogaloo.ttf", 50)
    love.graphics.setFont(boogaloo)

    hits = 0
    misses = 0
    local fullpath = "levels/" .. currentlevel
    local contents, size = love.filesystem.read(fullpath)

    if contents then
        meta = json.decode(contents)
    end
end

function CurrentLevel:draw()
    love.graphics.clear(0.3, 0.3, 0.34)
    --love.graphics.print(meta.metadata.Name, 10, 10)
    --love.graphics.print(meta.metadata.Creator, 10, 60)
end

return CurrentLevel