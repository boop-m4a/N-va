local flux = require "libs.flux"
local lovepatch = require "libs.lovepatch"
--local Inky = require "libs.Inky.inky"

_G.buttonPatches = _G.buttonPatches or {}
_G.lastClickedButton = nil
_G.buttonOffsets = _G.buttonOffsets or {}

function button(img, x, y, padx, pady, text, varname, val)
    
    btn = {
        image = img,
        x = x, y = y, w = 608, h = 100,
        padx = padx, pady = pady,
        text = text
    }
    
end

fucntion btndraw(target)
    if checkMouseOverImage(target) and love.mouse.isDown(1) then

        love.graphics.setColor(0.65, 0.65, 0.65)
        btn.y= btn.y+10
        love.graphics.draw(btn.image, btn.x, btn.y)
        btn.y= btn.y-10
        love.graphics.setColor(1, 1, 1)
        _G[varname] = val

    elseif checkMouseOverImage(target) then

        love.graphics.setColor(0.85, 0.85, 0.85)
        love.graphics.draw(target.image, target.x, target.y)
        love.graphics.setColor(1, 1, 1)

    else

        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(target.image, target.x, target.y)
    end
    

    if love.mouse.isDown(1) then
        if varname and checkMouseOverImage(btn) then
            if _G.lastClickedButton ~= varname then
                _G[varname] = val
                _G.lastClickedButton = varname                 
            end
        end
    else
        if varname and _G.lastClickedButton == varname then
            _G.lastClickedButton = nil
        end
    end

    love.graphics.print(target.text, target.x+target.padx, target.y-target.pady)
    breathe(target)
end

function checkMouseOverImage(target)
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
    init()

    startb = love.graphics.newImage("assets/button.png")
    button(startb, 0, 400, 20, -7, 12, 12, "Start", valal, 5)

    love.window.setMode(608, 1080, {
        love.window.setTitle("N+va"),
        resizable = false,
        fullscreen = true,
    })
end

function init()
    love.window.setMode(0, 0, {
        love.window.setTitle("N+va"),
        resizable = false,
        fullscreen = true,
    })

    love.graphics.setDefaultFilter("nearest", "nearest")

    love.resize(love.graphics.getDimensions())

    page = 0

    startlogo = love.graphics.newImage("assets/logo.png")
    logo = {size = 1, y = 1080}

    flux.to(logo, 2, {size = 2, y = 300}):ease("expoout")

end

local valal = 6

function menudraw()
    love.graphics.clear(0.1, 0.1, 0.17, 1)
    love.graphics.setColor(1, 1, 1)

    love.graphics.print("FPS: " .. fps, 10, 10)

    buttondraw(btn)
end



function menupd(dt)
    flux.update(dt)
    fps = love.timer.getFPS()
end

local mx = love.mouse.getX()
local my = love.mouse.getY()

function love.update(dt)
    menupd(dt)
    flux.update(dt)
end

function love.draw(dt)
    love.graphics.clear(0, 0, 0)

    love.graphics.setScissor(viewX, viewY, viewW, viewH)

    love.graphics.push()
    love.graphics.translate(viewX, viewY)

    boxfont = love.graphics.newFont("bogaloo.ttf", 70)
    love.graphics.setFont(boxfont)

    

    menudraw()

    --img, x, y, padx, pady, text, var, val
    

    love.graphics.pop()
    love.graphics.setScissor()
end
