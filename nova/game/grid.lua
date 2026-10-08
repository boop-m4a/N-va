-- game/grid.lua
-- All the maths that turns level coordinates (cells / rows) into time and into
-- screen pixels. Pure functions: no drawing, no state. The level editor will
-- reuse this exact file, so playing and editing can never disagree.
--
--   x : column, 0 (left) .. 15 (right). Can be fractional.
--   y : row. Row 0 is the first beat of the song, higher rows come LATER and
--       are drawn further UP the screen (objects fall towards the hit line).
--
-- A cell (x, y) is centred on row y, so a star at y=4 is exactly on the hit
-- line at the moment row 4 is "now".

local grid = {}

grid.SIZE   = 38      -- px per cell
grid.COLS   = 16      -- 16 * 38 = 608 = screen width
grid.VIEW_W = 608
grid.VIEW_H = 1080
grid.HUD_Y  = 830     -- top of assets/backing.png
grid.HIT_Y  = 740     -- screen y where objects must be clicked

-- timing = the song's tempo information, built once per level.
function grid.newTiming(bpm, rowsPerBeat, offset)
    local secPerRow = 60 / bpm / rowsPerBeat
    return {
        bpm = bpm,
        rowsPerBeat = rowsPerBeat,
        offset = offset,          -- seconds of audio before row 0
        secPerRow = secPerRow,
        secPerBeat = 60 / bpm,
        speed = grid.SIZE / secPerRow,  -- scroll speed in px/s
    }
end

function grid.rowToTime(tm, row) return tm.offset + row * tm.secPerRow end
function grid.timeToRow(tm, t)   return (t - tm.offset) / tm.secPerRow end

-- Screen y of the centre of `row` while the song is at `nowRow`.
function grid.rowToScreenY(row, nowRow)
    return grid.HIT_Y - (row - nowRow) * grid.SIZE
end

-- Screen rectangle (x, y, w, h) of an object (needs o.x o.y o.w o.h in cells).
function grid.objectRect(o, nowRow)
    local S = grid.SIZE
    local top    = grid.rowToScreenY(o.y + o.h - 1, nowRow) - S / 2
    local bottom = grid.rowToScreenY(o.y, nowRow) + S / 2
    return o.x * S, top, o.w * S, bottom - top
end

-- Inverse: which cell is under a screen pixel? (for the future editor)
function grid.screenToCell(px, py, nowRow)
    local col = math.floor(px / grid.SIZE)
    local row = math.floor(nowRow + (grid.HIT_Y - py) / grid.SIZE + 0.5)
    return col, row
end

return grid
