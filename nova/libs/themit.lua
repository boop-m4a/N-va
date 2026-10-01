local suit = require 'libs.suit'

local function themit(target)
    suit.theme.color.normal  = {bg = {1, 117/255, 0/255}, fg = {220/255,220/255,220/255}}
    suit.theme.color.hovered = {bg = {1, 137/255, 5/255}, fg = {255,255,255}}
    suit.theme.color.active  = {bg = {15/255, 100/255, 60/255}, fg = {205/255,205/255,205/255}}

    suit.theme[target] = function(text, opt, x, y, w, h)
        local c = suit.theme.getColorForState(opt)
        local vertices = {
            x, y,
            x + w, y,
            x + w - h, y + h,
            x, y + h
        }
        love.graphics.setColor(c.bg)
        love.graphics.polygon("fill", vertices)
        love.graphics.setColor(c.fg)
        love.graphics.setFont(opt.font or suit.theme.font)
        love.graphics.printf(text, x, y + (h - suit.theme.font:getHeight())/2, w - h, "center")
    end
end

return themit