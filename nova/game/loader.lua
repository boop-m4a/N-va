-- game/loader.lua
-- Reads a level .json and turns it into a clean, ready-to-play table.
-- It is forgiving: a bad object or missing field produces a warning and a
-- default instead of crashing, so a typo in your level never kills the game.

local json  = require 'libs.json'
local grid  = require 'game.grid'
local types = require 'objects'

local loader = {}

-- "#RRGGBB", "#RGB" or {r,g,b} (0-1 or 0-255) -> {r,g,b} in 0-1, or nil.
local function parseColor(v)
    if type(v) == "string" then
        local hex = v:match("^#?(%x+)$")
        if hex and #hex == 3 then
            hex = hex:gsub(".", "%0%0")
        end
        if hex and (#hex == 6 or #hex == 8) then
            return {
                tonumber(hex:sub(1, 2), 16) / 255,
                tonumber(hex:sub(3, 4), 16) / 255,
                tonumber(hex:sub(5, 6), 16) / 255,
            }
        end
    elseif type(v) == "table" and #v >= 3 then
        local scale = (v[1] > 1 or v[2] > 1 or v[3] > 1) and 255 or 1
        return { v[1] / scale, v[2] / scale, v[3] / scale }
    end
    return nil
end

local function pick(t, ...)           -- first non-nil among several key spellings
    for _, k in ipairs({...}) do
        if t[k] ~= nil then return t[k] end
    end
    return nil   -- explicit: tonumber(pick(...)) must receive one value, even if it's nil
end

function loader.load(path)
    local contents = love.filesystem.read(path)
    if not contents then return nil, "Couldn't read " .. tostring(path) end
    local ok, data = pcall(json.decode, contents)
    if not ok then return nil, "JSON error in " .. path .. ":\n" .. tostring(data) end
    if type(data) ~= "table" then return nil, path .. " is not a level file." end
    return loader.build(data, path)
end

function loader.build(data, path)
    local warnings = {}
    local function warn(fmt, ...) warnings[#warnings + 1] = string.format(fmt, ...) end

    local meta = type(data.metadata) == "table" and data.metadata or {}
    local body = type(data.level)    == "table" and data.level    or {}

    -- ---- metadata & timing ----
    local bpm = tonumber(pick(meta, "BPM", "bpm"))
    if not bpm or bpm <= 0 then
        bpm = 120
        warn("metadata.BPM missing or invalid, using 120")
    end
    local rpb = tonumber(pick(meta, "RowsPerBeat", "rowsPerBeat", "rows_per_beat")) or 4
    if rpb <= 0 then rpb = 4; warn("RowsPerBeat must be > 0, using 4") end
    local offset = tonumber(pick(meta, "Offset", "offset")) or 0

    local description = pick(meta, "Description", "description")
    if type(description) == "table" then description = table.concat(description, " ") end

    local level = {
        path = path,
        warnings = warnings,
        meta = {
            name = pick(meta, "Name", "name") or "Untitled",
            creator = pick(meta, "Creator", "creator") or "Unknown",
            description = description or "",
            music = pick(meta, "Music", "music"),
            bpm = bpm, rowsPerBeat = rpb, offset = offset,
        },
        timing = grid.newTiming(bpm, rpb, offset),
    }

    -- ---- background ----
    local bgRaw = pick(body, "BackgroundColor", "backgroundColor")
    level.bg = parseColor(bgRaw)
    if bgRaw ~= nil and not level.bg then
        warn("BackgroundColor %q isn't a valid color (use \"#RRGGBB\"), using default", tostring(bgRaw))
    end

    -- ---- objects ----
    local objs = {}
    local list = body.objects
    if list ~= nil and type(list) ~= "table" then warn("level.objects must be a list"); list = nil end

    for i, raw in ipairs(list or {}) do
        local def = type(raw) == "table" and types[raw.type]
        if not def then
            warn("object #%d: unknown type %q (skipped)", i, type(raw) == "table" and tostring(raw.type) or "?")
        elseif type(raw.x) ~= "number" or type(raw.y) ~= "number" then
            warn("object #%d (%s): needs numeric x and y (skipped)", i, raw.type)
        else
            local o = {
                index = i,
                type  = raw.type,
                def   = def,
                raw   = raw,   -- the original JSON table: types can read custom fields from it
                x = raw.x, y = raw.y,
                w = tonumber(raw.w) or def.w or 1,
                h = tonumber(raw.h) or def.h or 1,
            }
            local hb = raw.has_hitbox
            if hb == nil then hb = true end
            o.hitbox = hb and true or false
            -- How the object interacts: decided by its TYPE, switched off by has_hitbox=false.
            o.interaction = o.hitbox and (def.interaction or "none") or "none"
            o.time = grid.rowToTime(level.timing, o.y)
            o.endTime = grid.rowToTime(level.timing, o.y + o.h - 1)
            if o.x < 0 or o.x + o.w > grid.COLS then
                warn("object #%d (%s): sticks out of the %d-column grid", i, raw.type, grid.COLS)
            end
            objs[#objs + 1] = o
        end
    end

    table.sort(objs, function(a, b)
        if a.y ~= b.y then return a.y < b.y end
        return a.index < b.index
    end)
    level.objects = objs

    local last, stars = 0, 0
    for _, o in ipairs(objs) do
        if o.endTime > last then last = o.endTime end
        if o.interaction == "click" then stars = stars + 1 end
    end
    level.endTime = last
    level.clickCount = stars
    return level
end

return loader
