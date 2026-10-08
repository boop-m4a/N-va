-- objects/block.lua
-- A solid block. With "has_hitbox": true it is an obstacle: touching it with the
-- cursor hurts. With "has_hitbox": false it is pure decoration.
--
-- OBJECT TYPE CONTRACT (all fields optional except draw):
--   interaction = "click"  -> must be clicked on the beat (like a star)
--               = "hazard" -> hurts when the cursor touches it
--               = "none"   -> scenery
--   w, h        default size in cells
--   layer       draw order, lowest first (default 1)
--   load()      called once, load your images here
--   draw(o, x, y, w, h, ctx)  x,y,w,h = screen rectangle in px
--                              ctx.now (s), ctx.beat (fractional), ctx.debug
--   o.state     nil | "hit" | "missed" | "struck"  (set by the level screen)
--   o.raw       the original json table, for custom per-object fields

local Block = { interaction = "hazard", layer = 1 }

local image

function Block.load()
    if love.filesystem.getInfo("assets/block.png") then   -- optional art: drop one in and it's used
        image = love.graphics.newImage("assets/block.png")
    end
end

function Block.draw(o, x, y, w, h, ctx)
    if image then
        local S = w / o.w
        for cx = 0, o.w - 1 do
            for cy = 0, o.h - 1 do
                love.graphics.setColor(1, 1, 1, o.hitbox and 1 or 0.5)
                love.graphics.draw(image, x + cx * S, y + cy * S, 0, S / image:getWidth(), S / image:getHeight())
            end
        end
        return
    end

    if o.hitbox then
        if o.state == "struck" then love.graphics.setColor(1, 1, 1)
        else                        love.graphics.setColor(1, 117/255, 0) end
        love.graphics.rectangle("fill", x + 1, y + 1, w - 2, h - 2)
        love.graphics.setColor(0.45, 0.2, 0)
        love.graphics.rectangle("line", x + 1.5, y + 1.5, w - 3, h - 3)
    else
        love.graphics.setColor(0.32, 0.32, 0.5, 0.8)
        love.graphics.rectangle("fill", x + 1, y + 1, w - 2, h - 2)
    end
end

return Block
