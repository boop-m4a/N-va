-- objects/star.lua
-- A star you click on the beat (cursor over it + mouse button).
-- assets/star.png is a strip of 14 frames, 21x21 each; it spins in time with the beat.

local Star = { interaction = "click", layer = 2, w = 1, h = 1 }

local image, quads
local FRAMES, FW, FH, SCALE = 14, 21, 21, 2

function Star.load()
    image = love.graphics.newImage("assets/star.png")
    quads = {}
    for i = 1, FRAMES do
        quads[i] = love.graphics.newQuad((i - 1) * FW, 0, FW, FH, image:getDimensions())
    end
end

function Star.draw(o, x, y, w, h, ctx)
    if o.state == "hit" then return end                    -- consumed: effects take over
    local cx = math.floor(x + w / 2 + 0.5)
    local cy = math.floor(y + h / 2 + 0.5)                 -- whole pixels keep pixel art crisp
    local frame = math.floor(ctx.beat * FRAMES / 2) % FRAMES + 1   -- one full spin per 2 beats
    local alpha = 1
    if o.state == "missed" then alpha = 0.3
    elseif not o.hitbox then alpha = 0.5 end               -- has_hitbox=false: decorative star
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(image, quads[frame], cx, cy, 0, SCALE, SCALE, FW / 2, FH / 2)
end

return Star
