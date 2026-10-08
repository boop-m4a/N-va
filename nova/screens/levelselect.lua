local suit    = require 'libs.suit'
local manager = require 'manager'
local level = require 'screens.level'
local json = require 'libs.json'
local themit = require 'libs.themit'
local f = require 'libs.trans'

local LevelSelect = {}

function LevelSelect:enter()
    self.ui = suit.new()
    themit("Button")

    self.level_list = {}

    local files = love.filesystem.getDirectoryItems("levels")

    for i, filename in ipairs(files) do
        if filename:lower():match("%.json$") then
            local filepath = "levels/" .. filename
            local contents = love.filesystem.read(filepath)
            local displayName = filename:gsub("%.json$", "")

            if contents then
                local success, level_data = pcall(json.decode, contents)
                if success and type(level_data) == "table" and level_data.metadata then
                    displayName = level_data.metadata.Name or displayName
                end
            end

            table.insert(self.level_list, {
                path = filepath,
                name = displayName
            })
        end
    end
end

local currentPage = 1
local itemsPerPage = 9

function LevelSelect:update()
    if love.keyboard.isDown("escape") then
            manager:enter(require 'screens.mainmenu')
    end
    
    mousepos()

    suit.layout:reset(0, 40)
    suit.layout:padding(10, 20)

    local startIndex = ((currentPage - 1) * itemsPerPage) + 1
    local endIndex = math.min(startIndex + itemsPerPage - 1, #self.level_list)

    for i = startIndex, endIndex do
        local levelData = self.level_list[i]
        if suit.Button(levelData.name, suit.layout:row(400, 75, 20)).hit then
            currentlevel = levelData.path
            manager:enter(level)
        end
    end

    suit.layout:reset(10, 990) 

    
        if suit.Button("<", suit.layout:col(120, 40)).hit then
            if currentPage > 1 then
                currentPage = currentPage - 1
            end
        end


    local maxPages = math.ceil(#self.level_list / itemsPerPage)

        suit.Label(currentPage .. "/" .. maxPages, suit.layout:col(148, 40))



        if suit.Button(">", suit.layout:col(120, 40)).hit then
            if maxPages > 1 then
                currentPage = currentPage + 1
            end
        end

end

function LevelSelect:draw()
    startframe()

    love.graphics.clear(0.17, 0.17, 0.28)   
    suit.draw()

    endframe()
end

return LevelSelect