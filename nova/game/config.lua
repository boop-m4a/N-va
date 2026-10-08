-- game/config.lua
-- Every tunable number of the gameplay lives here, so you can tweak the feel
-- of the game without touching any logic.

local config = {}

-- Judgement windows, from strictest to loosest. `time` is the allowed error in
-- seconds (before OR after the star's exact beat). Add/remove/rename freely.
config.windows = {
    { name = "Perfect", time = 0.045, score = 300, accuracy = 1.00, color = {0.55, 1.00, 0.75} },
    { name = "Great",   time = 0.090, score = 200, accuracy = 0.70, color = {0.60, 0.85, 1.00} },
    { name = "OK",      time = 0.135, score = 100, accuracy = 0.40, color = {1.00, 0.90, 0.50} },
}
-- A star that wasn't clicked this long after its beat counts as a miss.
config.missWindow = config.windows[#config.windows].time

config.hitRadius    = 36   -- px: how close the cursor must be to a star when you click
config.cursorRadius = 5    -- px: the cursor's "body" for touching obstacles

config.health = {
    start    = 1.0,
    onHit    = 0.02,   -- gained per star hit
    onMiss   = -0.06,  -- lost per missed star
    onHazard = -0.10,  -- lost per obstacle touched
}
config.noFail = false      -- true = health can never end the level (handy for testing)

config.leadInMin  = 1.5    -- minimum seconds of empty screen before the first beat
config.resultsDelay = 1.5  -- seconds after the last object before the results screen
config.metronome  = true   -- tick on every beat when a level has no Music

config.defaultBackground = {0.17, 0.17, 0.28}

-- Minimum accuracy (0-1) for each letter grade, best first.
config.grades = { {0.95, "S"}, {0.90, "A"}, {0.80, "B"}, {0.70, "C"}, {0, "D"} }

return config
