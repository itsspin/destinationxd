------------------------------------------------------------------------
-- DestinationXD - FloorData.lua
-- Known multi-level areas with Z-range boundaries
-- Critical for elevation tracking in buildings, caves, and cities
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

-- Floor data format:
-- [mapID] = {
--     { name = "Floor Name", zMin = lowest_z, zMax = highest_z },
--     ...
-- }
-- Floors are ordered from lowest to highest

DXD.FloorData = {
    -----------------------------------------------------------------
    -- MIDNIGHT ZONES (Quel'Thalas - Active Content Priority)
    -----------------------------------------------------------------

    -- Silvermoon City (Renewed) - Multi-level walkways and spires
    [2602] = {
        { name = "Underground",      zMin = -50,  zMax = -5 },
        { name = "Ground Level",     zMin = -5,   zMax = 25 },
        { name = "Upper Walkways",   zMin = 25,   zMax = 55 },
        { name = "Spire Level",      zMin = 55,   zMax = 120 },
    },

    -- The Sunwell Plateau
    [2605] = {
        { name = "Lower Sanctum",    zMin = -30,  zMax = 10 },
        { name = "Main Level",       zMin = 10,   zMax = 40 },
        { name = "Upper Terrace",    zMin = 40,   zMax = 80 },
    },

    -----------------------------------------------------------------
    -- ORIGINAL SILVERMOON CITY
    -----------------------------------------------------------------
    [110] = {
        { name = "Ground Level",     zMin = -10,  zMax = 30 },
        { name = "Elevated Walkway", zMin = 30,   zMax = 60 },
    },

    -----------------------------------------------------------------
    -- MAJOR CITIES
    -----------------------------------------------------------------

    -- Stormwind City
    [84] = {
        { name = "Canals/Sewers",    zMin = -40,  zMax = 5 },
        { name = "Street Level",     zMin = 5,    zMax = 30 },
        { name = "Upper Level",      zMin = 30,   zMax = 60 },
        { name = "Keep/Towers",      zMin = 60,   zMax = 120 },
    },

    -- Orgrimmar
    [85] = {
        { name = "Cleft of Shadow",  zMin = -30,  zMax = 5 },
        { name = "Valley Floor",     zMin = 5,    zMax = 35 },
        { name = "Upper Bluffs",     zMin = 35,   zMax = 70 },
    },

    -- Ironforge
    [87] = {
        { name = "Deeprun Tram",     zMin = -100, zMax = -20 },
        { name = "Main Hall",        zMin = -20,  zMax = 15 },
        { name = "Upper Ring",       zMin = 15,   zMax = 40 },
    },

    -- Undercity
    [90] = {
        { name = "Sewers",           zMin = -60,  zMax = -25 },
        { name = "Main Level",       zMin = -25,  zMax = 5 },
        { name = "Ruins Above",      zMin = 5,    zMax = 40 },
    },

    -- Thunder Bluff
    [88] = {
        { name = "Base Camp",        zMin = -20,  zMax = 10 },
        { name = "Lower Rise",       zMin = 10,   zMax = 40 },
        { name = "High Rise",        zMin = 40,   zMax = 80 },
        { name = "Spirit Rise",      zMin = 80,   zMax = 120 },
    },

    -- Darnassus
    [89] = {
        { name = "Ground Level",     zMin = -10,  zMax = 30 },
        { name = "Tree Platforms",   zMin = 30,   zMax = 80 },
    },

    -----------------------------------------------------------------
    -- EXPANSION HUB CITIES
    -----------------------------------------------------------------

    -- Dalaran (Broken Isles)
    [627] = {
        { name = "Underbelly",       zMin = -30,  zMax = 5 },
        { name = "Main Level",       zMin = 5,    zMax = 35 },
        { name = "Upper Spires",     zMin = 35,   zMax = 80 },
    },

    -- Dalaran (Northrend)
    [125] = {
        { name = "Underbelly",       zMin = -30,  zMax = 5 },
        { name = "Main Level",       zMin = 5,    zMax = 35 },
        { name = "Upper Spires",     zMin = 35,   zMax = 80 },
    },

    -- Oribos
    [1670] = {
        { name = "Ring of Fates",    zMin = -20,  zMax = 15 },
        { name = "Ring of Transference", zMin = 15, zMax = 40 },
        { name = "Idyllia",          zMin = 40,   zMax = 70 },
    },

    -- Valdrakken
    [2112] = {
        { name = "Ground Level",     zMin = -10,  zMax = 30 },
        { name = "Mid Terraces",     zMin = 30,   zMax = 60 },
        { name = "Upper Terraces",   zMin = 60,   zMax = 100 },
    },

    -- Dornogal
    [2339] = {
        { name = "Underground",      zMin = -40,  zMax = 0 },
        { name = "Ground Level",     zMin = 0,    zMax = 30 },
        { name = "Upper Level",      zMin = 30,   zMax = 60 },
    },

    -----------------------------------------------------------------
    -- NOTABLE MULTI-FLOOR DUNGEONS/AREAS
    -----------------------------------------------------------------

    -- Blackrock Mountain area
    [36] = {  -- Burning Steppes
        { name = "Mountain Interior", zMin = -100, zMax = -10 },
        { name = "Surface",          zMin = -10,  zMax = 50 },
    },

    -- Boralus
    [1161] = {
        { name = "Harbor Level",     zMin = -10,  zMax = 20 },
        { name = "City Level",       zMin = 20,   zMax = 50 },
        { name = "Upper Terraces",   zMin = 50,   zMax = 80 },
    },

    -- Dazar'alor
    [1165] = {
        { name = "Harbor",           zMin = -10,  zMax = 15 },
        { name = "Market",           zMin = 15,   zMax = 40 },
        { name = "Grand Bazaar",     zMin = 40,   zMax = 65 },
        { name = "Temple Summit",    zMin = 65,   zMax = 120 },
    },

    -----------------------------------------------------------------
    -- CAVES AND UNDERGROUND AREAS (generic patterns)
    -----------------------------------------------------------------

    -- Azj-Kahet (underground zone)
    [2255] = {
        { name = "Deep Caverns",     zMin = -200, zMax = -80 },
        { name = "Mid Tunnels",      zMin = -80,  zMax = -20 },
        { name = "Upper Caverns",    zMin = -20,  zMax = 30 },
        { name = "Surface",          zMin = 30,   zMax = 100 },
    },

    -- The Ringing Deeps
    [2214] = {
        { name = "Deep Level",       zMin = -150, zMax = -50 },
        { name = "Mid Level",        zMin = -50,  zMax = 10 },
        { name = "Surface Access",   zMin = 10,   zMax = 60 },
    },
}
