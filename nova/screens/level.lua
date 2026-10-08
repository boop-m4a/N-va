-- screens/level.lua
-- The playable level screen.
--
-- Flow:  enter -> start() loads the json -> "playing" -> results / failed
--        Esc = pause, R = reload the json and restart, G = debug grid.
--
-- States: playing | resuming | paused | results | failed | notice
--
-- Where things live:
--   game/config.lua   numbers you'll want to tweak (windows, health, radius...)
--   game/grid.lua     cell <-> time <-> pixel maths
--   game/loader.lua   json -> level table
--   objects/*.lua     one file per object type (block, star, ...)

local manager = require 'manager'
local suit    = require 'libs.suit'
local themit  = require 'libs.themit'
require 'libs.trans'                       -- gives us mousepos / gamemouse / startframe / endframe
local grid        = require 'game.grid'
local loader      = require 'game.loader'
local config      = require 'game.config'
local objectTypes = require 'objects'

local Level = {}

local DARK = {0.17, 0.17, 0.28}
local fonts, backing, tickSource
local assetsLoaded = false

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function loadAssets()
    if assetsLoaded then return end
    fonts = {
        huge  = love.graphics.newFont("assets/bogaloo.ttf", 140),
        big   = love.graphics.newFont("assets/bogaloo.ttf", 50),
        mid   = love.graphics.newFont("assets/bogaloo.ttf", 36),
        small = love.graphics.newFont("assets/bogaloo.ttf", 24),
    }
    backing = love.graphics.newImage("assets/backing.png")
    for _, def in pairs(objectTypes) do
        if def.load then def.load() end
    end

    assetsLoaded = true
end

local function circleRect(cx, cy, r, x, y, w, h)
    local nx = clamp(cx, x, x + w)
    local ny = clamp(cy, y, y + h)
    local dx, dy = cx - nx, cy - ny
    return dx * dx + dy * dy <= r * r
end

-- Does a circle travelling (x0,y0)->(x1,y1) touch the rectangle at any point?
-- Sampling along the path stops fast mouse flicks from tunnelling through obstacles.
local function sweptCircleRect(x0, y0, x1, y1, r, rx, ry, rw, rh)
    local dist = math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2)
    local steps = math.max(1, math.ceil(dist / r))
    for i = 0, steps do
        local f = i / steps
        if circleRect(x0 + (x1 - x0) * f, y0 + (y1 - y0) * f, r, rx, ry, rw, rh) then
            return true
        end
    end
    return false
end

local function shadowText(text, x, y, limit, align, color)
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.printf(text, x + 2, y + 2, limit, align)
    love.graphics.setColor(color or {1, 1, 1})
    love.graphics.printf(text, x, y, limit, align)
end

---------------------------------------------------------------------------
-- lifecycle
---------------------------------------------------------------------------
function Level:enter()
    loadAssets()
    suit.theme.font = fonts.big
    themit("Button")
    self.debug = false
    self:start()
end

function Level:leave()
    self:stopMusic()
    love.mouse.setVisible(true)
    love.mouse.setGrabbed(false)
end

function Level:stopMusic()
    if self.music then self.music:stop() end
    self.music = nil
end

-- (Re)loads the level file from disk and begins from the top.
-- Editing the json and pressing R is the fast way to iterate on a level.
function Level:start()
    self:stopMusic()
    self.stateTime = 0
    self.effects = {}
    self.active = {}
    self.flash = 0
    self.clickPulse = 0

    local lv, err = loader.load(currentlevel)
    self.level = lv
    if not lv then
        self.notice = { title = "Couldn't load level", text = err }
        return self:setState("notice")
    end
    for _, w in ipairs(lv.warnings) do print("[level warning] " .. w) end
    if #lv.objects == 0 then
        self.notice = { title = lv.meta.name, text = "This level has no objects yet.\nAdd some to \"level\" > \"objects\" in the json,\nthen press R to reload." }
        return self:setState("notice")
    end

    self.timing = lv.timing
    self.leadIn = math.max(config.leadInMin, grid.HIT_Y / lv.timing.speed + 0.5)
    self.songTime = -self.leadIn
    self.lastReal = love.timer.getTime()
    self.lo = 1
    self.lastBeat = math.floor(grid.timeToRow(lv.timing, self.songTime) / lv.timing.rowsPerBeat) - 1
    self.health = config.health.start
    self.stats = { score = 0, combo = 0, maxCombo = 0, counts = {}, misses = 0,
                   hazards = 0, judged = 0, accSum = 0 }
    for _, w in ipairs(config.windows) do self.stats.counts[w.name] = 0 end

    if lv.meta.music then
        local ok, src = pcall(love.audio.newSource, lv.meta.music, "stream")
        if ok then self.music = src
        else print("[level warning] couldn't load music: " .. tostring(lv.meta.music)) end
    end
    self.musicStarted = false

    local rx, ry = gamemouse()
    self.cursor = { x = clamp(rx, 0, grid.VIEW_W), y = clamp(ry, 0, grid.VIEW_H) }
    self.prevCursor = { x = self.cursor.x, y = self.cursor.y }
    self:setState("playing")
end

function Level:setState(s)
    self.state = s
    self.stateTime = 0
    local playing = (s == "playing" or s == "resuming")
    love.mouse.setVisible(not playing)
    love.mouse.setGrabbed(playing)
end

---------------------------------------------------------------------------
-- pause / resume / finish / quit
---------------------------------------------------------------------------
function Level:pause()
    if self.state ~= "playing" and self.state ~= "resuming" then return end
    if self.music and self.musicStarted then self.music:pause() end
    self:setState("paused")
end

function Level:resume()
    self.resumeTimer = 1.5
    self:setState("resuming")
end

function Level:finish(failed)
    self:stopMusic()
    self:setState(failed and "failed" or "results")
end

function Level:quit()
    manager:enter(require 'screens.levelselect')   -- required lazily: levelselect requires this file
end

---------------------------------------------------------------------------
-- time
---------------------------------------------------------------------------
-- Song time right now, including the part of the frame already elapsed, so a
-- click is judged at the moment it happened and not at the last frame's time.
function Level:currentTime()
    if self.state ~= "playing" then return self.songTime end
    return self.songTime + math.min(love.timer.getTime() - self.lastReal, 0.05)
end

---------------------------------------------------------------------------
-- update
---------------------------------------------------------------------------
function Level:update(dt)
    mousepos()
    dt = math.min(dt, 0.05)
    self.stateTime = self.stateTime + dt
    self.flash = math.max(0, self.flash - dt)
    self.clickPulse = math.max(0, self.clickPulse - dt * 6)

    for i = #self.effects, 1, -1 do
        local e = self.effects[i]
        e.age = e.age + dt
        if e.age >= e.life then table.remove(self.effects, i) end
    end

    if self.state == "playing" then
        self:updateCursor(true)
        self:updatePlaying(dt)
    elseif self.state == "resuming" then
        self:updateCursor(true)
        self.resumeTimer = self.resumeTimer - dt
        if self.resumeTimer <= 0 then
            if self.music and self.musicStarted then self.music:play() end
            self.lastReal = love.timer.getTime()
            self:setState("playing")
        end
    else
        self:menuButtons()
    end
end

function Level:updateCursor(keepInside)
    local gx, gy = gamemouse()
    local cx, cy = clamp(gx, 0, grid.VIEW_W), clamp(gy, 0, grid.VIEW_H)
    if keepInside and (cx ~= gx or cy ~= gy) and love.window.hasFocus() then
        local rx, ry = love.mouse.getPosition()
        love.mouse.setPosition(rx + (cx - gx), ry + (cy - gy))   -- keep the real pointer in the play area
    end
    self.prevCursor.x, self.prevCursor.y = self.cursor.x, self.cursor.y
    self.cursor.x, self.cursor.y = cx, cy
end

function Level:updatePlaying(dt)
    local lv, tm = self.level, self.timing
    self.songTime = self.songTime + dt
    self.lastReal = love.timer.getTime()

    -- audio: start on beat 0 and keep our clock honest if it drifts
    if self.music then
        if not self.musicStarted and self.songTime >= 0 then
            self.music:play()
            self.musicStarted = true
        elseif self.musicStarted and self.music:isPlaying() then
            local at = self.music:tell("seconds")
            if math.abs(at - self.songTime) > 0.08 then self.songTime = at end
        end
    end
    local t = self.songTime
    local nowRow = grid.timeToRow(tm, t)

    -- metronome (only for levels without music)
    if not self.music and config.metronome then
        local beat = math.floor(nowRow / tm.rowsPerBeat)
        if beat > self.lastBeat then
            self.lastBeat = beat
            if beat >= 0 then tickSource:stop(); tickSource:play() end
        end
    end

    self:updateActive(nowRow)
    self:processMisses(t)
    self:processHazards(nowRow)

    if self.health <= 0 and not config.noFail then
        self:finish(true)
    elseif t > lv.endTime + config.resultsDelay then
        self:finish(false)
    end
end

-- Builds the list of objects currently on (or near) the screen.
-- Objects are sorted by row, so we can stop looking as soon as we pass the top.
function Level:updateActive(nowRow)
    local objs = self.level.objects
    local S = grid.SIZE
    local rowMin = nowRow - (grid.VIEW_H - grid.HIT_Y) / S - 1
    local rowMax = nowRow + grid.HIT_Y / S + 1

    -- skip the finished prefix (anything fully below the screen)
    while self.lo <= #objs and objs[self.lo].y + objs[self.lo].h - 1 < rowMin do
        local o = objs[self.lo]
        if o.interaction == "click" and not o.state then   -- safety net after a lag spike
            o.state = "missed"
            self:registerMiss()
        end
        self.lo = self.lo + 1
    end

    local active = {}
    for i = self.lo, #objs do
        local o = objs[i]
        if o.y > rowMax then break end
        if o.y + o.h - 1 >= rowMin then active[#active + 1] = o end
    end
    self.active = active
end

function Level:processMisses(t)
    for _, o in ipairs(self.active) do
        if o.interaction == "click" and not o.state and t > o.time + config.missWindow then
            o.state = "missed"
            self:registerMiss(o)
        end
    end
end

function Level:processHazards(nowRow)
    local r = config.cursorRadius
    local p, c = self.prevCursor, self.cursor
    for _, o in ipairs(self.active) do
        if o.interaction == "hazard" and not o.state then
            local x, y, w, h = grid.objectRect(o, nowRow)
            if sweptCircleRect(p.x, p.y, c.x, c.y, r, x, y, w, h) then
                o.state = "struck"
                self:registerHazard()
            end
        end
    end
end

---------------------------------------------------------------------------
-- scoring
---------------------------------------------------------------------------
function Level:addHealth(amount)
    self.health = clamp(self.health + amount, 0, 1)
end

function Level:popup(text, x, y, color)
    self.effects[#self.effects + 1] = { kind = "text", text = text, x = x, y = y, color = color, age = 0, life = 0.6 }
end

function Level:registerHit(o, win)
    local s = self.stats
    s.score = s.score + win.score
    s.combo = s.combo + 1
    s.maxCombo = math.max(s.maxCombo, s.combo)
    s.counts[win.name] = s.counts[win.name] + 1
    s.judged = s.judged + 1
    s.accSum = s.accSum + win.accuracy
    self:addHealth(config.health.onHit)
    local cx = (o.x + o.w / 2) * grid.SIZE
    self:popup(win.name, cx, grid.HIT_Y - 30, win.color)
    self.effects[#self.effects + 1] = { kind = "ring", x = cx, y = grid.HIT_Y, color = win.color, age = 0, life = 0.3 }
end

function Level:registerMiss(o)
    local s = self.stats
    s.misses = s.misses + 1
    s.judged = s.judged + 1
    s.combo = 0
    self:addHealth(config.health.onMiss)
    if o then self:popup("Miss", (o.x + o.w / 2) * grid.SIZE, grid.HIT_Y - 30, {1, 0.4, 0.4}) end
end

function Level:registerHazard()
    local s = self.stats
    s.hazards = s.hazards + 1
    s.combo = 0
    self.flash = 0.35
    self:addHealth(config.health.onHazard)
    self:popup("Ouch!", self.cursor.x, self.cursor.y - 24, {1, 0.5, 0.2})
end

function Level:accuracy()
    local s = self.stats
    if s.judged == 0 then return 1 end
    return s.accSum / s.judged
end

function Level:grade()
    local acc = self:accuracy()
    for _, g in ipairs(config.grades) do
        if acc >= g[1] then return g[2] end
    end
    return "D"
end

---------------------------------------------------------------------------
-- input
---------------------------------------------------------------------------
-- Click: find the star closest in TIME that is also under the cursor.
function Level:click()
    self.clickPulse = 1
    local t = self:currentTime()
    local nowRow = grid.timeToRow(self.timing, t)
    local cx, cy = self.cursor.x, self.cursor.y

    local best, bestErr, bestDist
    for _, o in ipairs(self.active) do
        if o.interaction == "click" and not o.state then
            local err = math.abs(t - o.time)
            if err <= config.missWindow then
                local rx, ry, rw, rh = grid.objectRect(o, nowRow)
                local dist = math.sqrt((cx - (rx + rw / 2)) ^ 2 + (cy - (ry + rh / 2)) ^ 2)
                if dist <= config.hitRadius and
                   (not best or err < bestErr - 1e-6 or (math.abs(err - bestErr) <= 1e-6 and dist < bestDist)) then
                    best, bestErr, bestDist = o, err, dist
                end
            end
        end
    end

    if best then
        for _, win in ipairs(config.windows) do
            if bestErr <= win.time then
                best.state = "hit"
                self:registerHit(best, win)
                break
            end
        end
    end
    -- clicking on nothing is free: no penalty
end

function Level:mousepressed(x, y, button)
    if self.state == "playing" and (button == 1 or button == 2) then
        local gx, gy = gamemouse()
        self.cursor.x, self.cursor.y = clamp(gx, 0, grid.VIEW_W), clamp(gy, 0, grid.VIEW_H)
        self:click()
    end
end

function Level:keypressed(key)
    if key == "escape" then
        if self.state == "playing" or self.state == "resuming" then self:pause()
        elseif self.state == "paused" then self:resume()
        else self:quit() end
    elseif key == "r" then
        self:start()
    elseif key == "g" then
        self.debug = not self.debug
    end
end

function Level:focus(focused)
    if not focused then self:pause() end
end

function Level:menuButtons()
    local x, w = (grid.VIEW_W - 500) / 2, 500
    if self.state == "paused" then
        if suit.Button("Resume",  x, 420, w, 100).hit then self:resume() end
        if suit.Button("Restart", x, 540, w, 100).hit then self:start() end
        if suit.Button("Quit",    x, 660, w, 100).hit then self:quit() end
    elseif self.state == "results" or self.state == "failed" then
        if self.stateTime > 0.7 then   -- grace period so a mashed click can't hit a button
            if suit.Button("Retry",        x, 830, w, 100).hit then self:start() end
            if suit.Button("Level Select", x, 950, w, 100).hit then self:quit() end
        end
    elseif self.state == "notice" then
        if suit.Button("Back", x, 830, w, 100).hit then self:quit() end
    end
end

---------------------------------------------------------------------------
-- draw
---------------------------------------------------------------------------
function Level:draw()
    startframe()
    local lv = self.level
    love.graphics.clear(unpack(lv and lv.bg or config.defaultBackground))

    local s = self.state
    if s == "playing" or s == "resuming" or s == "paused" then
        self:drawWorld()
        self:drawHud()
        if s == "paused" then
            love.graphics.setColor(0, 0, 0, 0.65)
            love.graphics.rectangle("fill", 0, 0, grid.VIEW_W, grid.VIEW_H)
            love.graphics.setFont(fonts.big)
            shadowText("Paused", 0, 300, grid.VIEW_W, "center")
        elseif s == "resuming" then
            love.graphics.setFont(fonts.big)
            shadowText("Get ready...", 0, 450, grid.VIEW_W, "center")
        end
    elseif s == "results" or s == "failed" then
        self:drawResults()
    elseif s == "notice" then
        love.graphics.setFont(fonts.big)
        shadowText(self.notice.title, 20, 260, grid.VIEW_W - 40, "center")
        love.graphics.setFont(fonts.small)
        shadowText(self.notice.text, 20, 360, grid.VIEW_W - 40, "center", {0.85, 0.85, 0.9})
    end

    suit.draw()
    endframe()
end

function Level:drawWorld()
    local tm = self.timing
    local t = self.songTime
    local nowRow = grid.timeToRow(tm, t)
    local ctx = { now = t, beat = nowRow / tm.rowsPerBeat, debug = self.debug }

    if self.debug then self:drawGrid(nowRow) end

    -- hit line
    love.graphics.setColor(1, 1, 1, 0.45)
    love.graphics.rectangle("fill", 0, grid.HIT_Y - 1, grid.VIEW_W, 3)

    -- objects, layer by layer (scenery < obstacles < stars)
    for layer = 1, 3 do
        for _, o in ipairs(self.active) do
            if (o.def.layer or 1) == layer and o.def.draw then
                local x, y, w, h = grid.objectRect(o, nowRow)
                o.def.draw(o, x, y, w, h, ctx)
            end
        end
    end

    -- effects
    love.graphics.setFont(fonts.small)
    for _, e in ipairs(self.effects) do
        local k = e.age / e.life
        if e.kind == "text" then
            love.graphics.setColor(e.color[1], e.color[2], e.color[3], 1 - k)
            love.graphics.printf(e.text, e.x - 100, e.y - k * 30, 200, "center")
        elseif e.kind == "ring" then
            love.graphics.setColor(e.color[1], e.color[2], e.color[3], 1 - k)
            love.graphics.setLineWidth(3)
            love.graphics.circle("line", e.x, e.y, 16 + k * 28)
            love.graphics.setLineWidth(1)
        end
    end

    -- intro title
    if t < 0 then
        local a = clamp(-t, 0, 1)
        love.graphics.setFont(fonts.big)
        shadowText(self.level.meta.name, 0, 380, grid.VIEW_W, "center", {1, 1, 1, a})
        love.graphics.setFont(fonts.small)
        shadowText("by " .. self.level.meta.creator, 0, 445, grid.VIEW_W, "center", {0.85, 0.85, 0.9, a})
    end

    -- cursor
    if self.state ~= "paused" then
        local c = self.cursor
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", c.x, c.y, 10 + self.clickPulse * 8)
        love.graphics.setLineWidth(1)
        love.graphics.circle("fill", c.x, c.y, config.cursorRadius)
    end

    -- damage flash
    if self.flash > 0 then
        love.graphics.setColor(1, 0.2, 0.1, self.flash)
        love.graphics.rectangle("fill", 0, 0, grid.VIEW_W, grid.VIEW_H)
    end
end

function Level:drawGrid(nowRow)
    local S, tm = grid.SIZE, self.timing
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 0.07)
    for i = 0, grid.COLS do
        love.graphics.line(i * S, 0, i * S, grid.VIEW_H)
    end
    local rowMin = math.floor(nowRow - (grid.VIEW_H - grid.HIT_Y) / S - 1)
    local rowMax = math.ceil(nowRow + grid.HIT_Y / S + 1)
    love.graphics.setFont(fonts.small)
    for r = rowMin, rowMax do
        local isBeat = (r % tm.rowsPerBeat == 0)
        local yEdge = grid.rowToScreenY(r - 0.5, nowRow)     -- cell boundary below row r
        love.graphics.setColor(1, 1, 1, isBeat and 0.16 or 0.06)
        love.graphics.line(0, yEdge, grid.VIEW_W, yEdge)
        if isBeat and r >= 0 then
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.print("row " .. r, 4, grid.rowToScreenY(r, nowRow) - 28)
        end
    end

    -- debug readout + level warnings
    love.graphics.setColor(1, 1, 0.6)
    love.graphics.print(string.format("t=%.2fs  row=%.1f  fps=%d  active=%d",
        self.songTime, nowRow, love.timer.getFPS(), #self.active), 4, 6)
    local y = 34
    for _, w in ipairs(self.level.warnings) do
        love.graphics.setColor(1, 0.8, 0.3)
        love.graphics.printf("! " .. w, 4, y, grid.VIEW_W - 8)
        y = y + 28
    end
end

function Level:drawHud()
    local lv, s = self.level, self.stats

    -- song progress (thin bar along the top)
    local progress = clamp(self.songTime / math.max(lv.endTime, 0.001), 0, 1)
    love.graphics.setColor(1, 1, 1, 0.35)
    love.graphics.rectangle("fill", 0, 0, grid.VIEW_W * progress, 4)

    if not self.debug and #lv.warnings > 0 then
        love.graphics.setFont(fonts.small)
        love.graphics.setColor(1, 0.8, 0.3, 0.8)
        love.graphics.print(#lv.warnings .. " level warning(s) - press G", 4, 8)
    end

    -- bottom panel
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(backing, 0, grid.HUD_Y)

    love.graphics.setFont(fonts.big)
    love.graphics.setColor(DARK)
    love.graphics.printf(string.format("%07d", s.score), 30, 872, 330, "left")
    love.graphics.printf(s.combo .. "x", 330, 872, 248, "right")

    love.graphics.setFont(fonts.small)
    love.graphics.setColor(DARK[1], DARK[2], DARK[3], 0.8)
    love.graphics.print(string.format("%.2f%%", self:accuracy() * 100), 30, 940)
    local c = s.counts
    love.graphics.printf(string.format("P %d  G %d  O %d  X %d",
        c.Perfect or 0, c.Great or 0, c.OK or 0, s.misses), 200, 940, 378, "right")

    -- health bar
    love.graphics.setColor(DARK[1], DARK[2], DARK[3], 0.25)
    love.graphics.rectangle("fill", 30, 995, 548, 16, 8, 8)
    local h = self.health
    love.graphics.setColor(1 - h * 0.7, 0.35 + h * 0.5, 0.3)
    love.graphics.rectangle("fill", 30, 995, math.max(16, 548 * h), 16, 8, 8)

    love.graphics.setColor(DARK[1], DARK[2], DARK[3], 0.7)
    love.graphics.print(lv.meta.name, 30, 1030)
end

function Level:drawResults()
    local s = self.state
    local failed = (s == "failed")
    love.graphics.setFont(fonts.big)
    shadowText(failed and "Failed" or "Level Complete", 0, 90, grid.VIEW_W, "center",
        failed and {1, 0.4, 0.4} or {1, 1, 1})
    love.graphics.setFont(fonts.small)
    shadowText(self.level.meta.name, 0, 150, grid.VIEW_W, "center", {0.85, 0.85, 0.9})

    love.graphics.setFont(fonts.huge)
    shadowText(failed and "F" or self:grade(), 0, 200, grid.VIEW_W, "center", {1, 117/255, 0})

    local st = self.stats
    love.graphics.setFont(fonts.mid)
    local lines = {
        string.format("Score  %07d", st.score),
        string.format("Accuracy  %.2f%%", self:accuracy() * 100),
        string.format("Max combo  %d", st.maxCombo),
    }
    for _, w in ipairs(config.windows) do
        lines[#lines + 1] = string.format("%s  %d", w.name, st.counts[w.name])
    end
    lines[#lines + 1] = string.format("Missed  %d", st.misses)
    lines[#lines + 1] = string.format("Obstacles hit  %d", st.hazards)
    for i, l in ipairs(lines) do
        shadowText(l, 0, 400 + (i - 1) * 46, grid.VIEW_W, "center")
    end
end

return Level
