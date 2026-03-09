------------------------------------------------------------------------
-- DestinationXD - Config.lua
-- Default settings - works out of box with zero configuration needed
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...
DXD.Config = {}
local Config = DXD.Config

------------------------------------------------------------------------
-- COLOR PALETTE - "Moonlight"
------------------------------------------------------------------------
Config.COLORS = {
    -- Text & UI Chrome
    TEXT_PRIMARY     = { r = 0.92, g = 0.92, b = 0.95, a = 0.90 },
    TEXT_SECONDARY   = { r = 0.75, g = 0.75, b = 0.80, a = 0.55 },
    TEXT_TERTIARY    = { r = 0.60, g = 0.60, b = 0.65, a = 0.35 },
    PANEL_BG         = { r = 0.03, g = 0.03, b = 0.06, a = 0.75 },
    PANEL_BG_HOVER   = { r = 0.10, g = 0.10, b = 0.15, a = 0.30 },
    DIVIDER          = { r = 0.40, g = 0.40, b = 0.45, a = 0.15 },

    -- Elevation States
    ELEV_ABOVE       = { r = 1.00, g = 0.60, b = 0.20, a = 0.90 },
    ELEV_BELOW       = { r = 0.30, g = 0.60, b = 1.00, a = 0.90 },
    ELEV_LEVEL       = { r = 0.30, g = 0.90, b = 0.50, a = 0.80 },

    -- Beacon Contextual Colors
    BEACON_QUEST     = { r = 1.00, g = 0.84, b = 0.00, a = 0.85 },
    BEACON_WAYPOINT  = { r = 0.40, g = 0.85, b = 1.00, a = 0.85 },
    BEACON_TOMTOM    = { r = 1.00, g = 0.55, b = 0.00, a = 0.85 },
    BEACON_CORPSE    = { r = 0.90, g = 0.25, b = 0.25, a = 0.70 },
    BEACON_FLIGHT    = { r = 0.27, g = 1.00, b = 0.53, a = 0.80 },
    BEACON_DUNGEON   = { r = 0.70, g = 0.45, b = 1.00, a = 0.80 },
    BEACON_TRAVEL    = { r = 0.88, g = 0.88, b = 0.92, a = 0.80 },

    -- Feedback
    ARRIVE_BLOOM     = { r = 1.00, g = 1.00, b = 1.00, a = 0.60 },
}

------------------------------------------------------------------------
-- FONT SIZES
------------------------------------------------------------------------
Config.FONT_SIZES = {
    DISTANCE_PRIMARY  = 18,
    ELEVATION_VALUE   = 14,
    LABEL             = 10,
    ZONE_NAME         = 13,
    ROUTE_STEP        = 11,
    HEADER            = 15,
}

------------------------------------------------------------------------
-- ANIMATION TIMINGS
------------------------------------------------------------------------
Config.ANIMATION = {
    BEACON_PULSE_PERIOD   = 3.0,
    BEACON_PULSE_CLOSE    = 1.5,
    BEACON_FADE_IN        = 0.4,
    BEACON_FADE_OUT       = 0.8,
    BEACON_ARRIVE_BLOOM   = 0.5,

    ARROW_LERP_FACTOR     = 0.35,
    ARROW_PITCH_LERP      = 0.25,

    ELEVATION_FADE        = 0.3,
    ELEVATION_IDLE_FADE   = 1.5,

    HUD_FADE_IN           = 0.25,
    HUD_FADE_OUT          = 0.4,

    TRAVEL_PANEL_OPEN     = 0.3,
    TRAVEL_PANEL_CLOSE    = 0.2,
    TRAVEL_HOVER          = 0.15,
}

------------------------------------------------------------------------
-- UPDATE FREQUENCIES (staggered for performance)
------------------------------------------------------------------------
Config.UPDATE_RATES = {
    POSITION      = 0,       -- every frame
    BEACON        = 0,       -- every frame (smooth beam)
    ELEVATION     = 0.10,    -- 10 fps
    DISTANCE      = 0.10,    -- 10 fps
    ARROW         = 0,       -- every frame (smooth arrow)
    OBSTRUCTION   = 0.50,    -- 2 fps
    SPEED         = 0.20,    -- 5 fps
}

------------------------------------------------------------------------
-- BEACON SETTINGS
------------------------------------------------------------------------
Config.BEACON = {
    -- Distance thresholds (yards)
    FAR_DISTANCE      = 100,
    MEDIUM_DISTANCE   = 30,
    CLOSE_DISTANCE    = 5,

    -- Pulse opacity range
    PULSE_MIN_ALPHA   = 0.80,
    PULSE_MAX_ALPHA   = 0.97,

    -- Beam visual - thin and elegant like WaypointUI
    BEAM_WIDTH_BASE   = 1.5,  -- pixels (core shaft - very thin)
    BEAM_HEIGHT_BASE  = 0,    -- 0 = extend to top of screen
    GLOW_WIDTH_BASE   = 5,    -- pixels (inner glow width)

    -- Close-range firefly bob
    BOB_AMPLITUDE     = 3,    -- pixels
    BOB_PERIOD        = 2.0,  -- seconds
}

------------------------------------------------------------------------
-- EDGE INDICATOR SETTINGS (off-screen diamond)
------------------------------------------------------------------------
Config.EDGE_INDICATOR = {
    SIZE              = 24,   -- diamond size
    MARGIN            = 45,   -- distance from screen edge
    ARROW_SIZE        = 12,   -- directional arrow size
    ARROW_OFFSET      = 16,   -- offset from diamond center
}

------------------------------------------------------------------------
-- OBSTRUCTION DETECTION
------------------------------------------------------------------------
Config.OBSTRUCTION = {
    SAMPLE_INTERVAL       = 0.5,
    SAMPLE_WINDOW         = 5.0,
    BEARING_THRESHOLD     = 30,
    DISTANCE_STALL_THRESHOLD = 2,
    MAX_SAMPLES           = 10,
}

------------------------------------------------------------------------
-- TRAVEL PLANNER
------------------------------------------------------------------------
Config.TRAVEL = {
    WALK_SPEED       = 7.0,    -- yards/sec base walking
    RUN_SPEED        = 10.5,   -- yards/sec running (100% speed)
    MOUNT_SPEED      = 21.0,   -- yards/sec ground mount (200%)
    FLY_SPEED        = 31.5,   -- yards/sec flying mount (310%)
    SKYRIDING_SPEED  = 42.0,   -- yards/sec Skyriding average
    PORTAL_CAST_TIME = 2.0,    -- seconds
    HS_CAST_TIME     = 10.0,   -- seconds
}

------------------------------------------------------------------------
-- DEFAULT SAVED VARIABLES
------------------------------------------------------------------------
Config.DEFAULTS = {
    -- General
    enabled = true,
    playSounds = true,
    autoClearOnArrival = true,
    arrivalDistance = 5,
    verticalTolerance = 8,

    -- Travel Planner
    considerHearthstoneCooldown = true,
    hearthstoneLocation = "auto",
    preferredFlightStyle = "shortest",

    -- Radial Quick Access Menu
    radialMenuEnabled = true,
    radialMenuKey = "`",

    -- Integrations
    tomtomCompat = true,
    handyNotesCompat = true,

    -- Minimap
    minimap = {
        hide = false,
        minimapPos = 225,
    },

}
