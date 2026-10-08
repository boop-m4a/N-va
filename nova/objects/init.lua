-- objects/init.lua
-- Auto-registers every object type. To add a new mechanic, drop a new file in
-- this folder (e.g. objects/laser.lua): the filename IS the "type" you write in
-- the level json. See objects/block.lua and objects/star.lua for the contract.

local registry = {}

for _, file in ipairs(love.filesystem.getDirectoryItems("objects")) do
    local name = file:match("^(.+)%.lua$")
    if name and name ~= "init" then
        registry[name] = require("objects." .. name)
    end
end

return registry
