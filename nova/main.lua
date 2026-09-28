local flux = require "libs.flux"
local lovepatch = require "libs.lovepatch"
--local Inky = require "libs.Inky.inky"

local button_h = 100
local button_w = 608

local buttons = {}

function newbtn(text, fn)
    return {
        text = text,
        fn = fn
    }
end

function hovering(target)
     local mx, my = love.mouse.getPosition()
    local winW, winH = love.graphics.getDimensions()

    local VIRTUAL_WIDTH = 608
    local VIRTUAL_HEIGHT = 1080
    
    local scale = math.min(winW / VIRTUAL_WIDTH, winH / VIRTUAL_HEIGHT)
    
    local offsetX = (winW - (VIRTUAL_WIDTH * scale)) / 2
    local offsetY = (winH - (VIRTUAL_HEIGHT * scale)) / 2
    
    local tx = (mx - offsetX) / scale
    local ty = (my - offsetY) / scale
    
    return tx >= target.x and
           tx <= target.x + target.w and
           ty >= target.y and
           ty <= target.y + target.h

end

function breathe(target)
    flux.to(target, 2, { y = target.y + 8 }):ease("sineinout")     
        :after(2, { y = target.y - 8 }):ease("sineinout")     
        :oncomplete(function()             
            breathe(target)         
        end) 
end


local viewW, viewH = 608, 1080
local viewX, viewY = 0, 0

function love.resize(w, h)
    viewX = (w - viewW) / 2
    viewY = (h - viewH) / 2
end

function love.load()


    table.insert(buttons, newbtn(
        "Start Game",
        function()
            print("Starting Game...", 100, 400)
        end))

        table.insert(buttons, newbtn(
        "Settings",
        function()
            print("Starting Settings Page...", 100, 500)
        end))

        table.insert(buttons, newbtn(
        "Quit",
        function()
            love.event.quit(0)
        end))

    

    logo()

    love.window.setMode(608, 1080, {
        love.window.setTitle("N+va"),
        resizable = false,
        fullscreen = true,
        vsync = false,
    })
    love.graphics.setDefaultFilter("nearest", "nearest")
end

function logo()

    love.resize(love.graphics.getDimensions())

    startlogo = love.graphics.newImage("assets/logo.png")
    logo = {size = 1, y = 1080}

    flux.to(logo, 2, {size = 2, y = 300}):ease("expoout")

end



function logodraw()
    love.graphics.clear(0.1, 0.1, 0.17, 1)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(startlogo, 54, logo.y, 0, logo.size, logo.size)
    love.graphics.print("FPS: " .. fps, 10, 10)
end

local mx = love.mouse.getX()
local my = love.mouse.getY()

function love.update(dt)
    flux.update(dt)
    fps = love.timer.getFPS()
end

function love.draw(dt)
    love.graphics.clear(0, 0, 0)

    love.graphics.setScissor(viewX, viewY, viewW, viewH)

    love.graphics.push()
    love.graphics.translate(viewX, viewY)

    boxfont = love.graphics.newFont("bogaloo.ttf", 70)
    love.graphics.setFont(boxfont)

    

    logodraw()

    for(i, button in ipairs(buttons) do)
        love.graphics
    end

    --img, x, y, padx, pady, text, varname, val
    

    love.graphics.pop()
    love.graphics.setScissor()
end
