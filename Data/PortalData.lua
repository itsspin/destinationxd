------------------------------------------------------------------------
-- DestinationXD - PortalData.lua
-- Comprehensive portal, teleport, and transport database
-- Every known portal network in WoW through Midnight
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

-- Portal entry format:
-- { srcMapID, srcX, srcY, dstMapID, dstX, dstY, faction, name, travelTime, type }
-- travelTime in seconds (cast time + loading screen)
-- type: "portal", "boat", "zeppelin", "tram", "mole_machine"

DXD.PortalData = {
    -----------------------------------------------------------------
    -- ORGRIMMAR PORTAL ROOM (Pathfinder's Den)
    -----------------------------------------------------------------
    -- To other capitals
    { srcMapID = 85, srcX = 0.455, srcY = 0.379, dstMapID = 88,   dstX = 0.5, dstY = 0.5, faction = "Horde", name = "Orgrimmar to Thunder Bluff",           travelTime = 3, type = "portal" },
    { srcMapID = 85, srcX = 0.460, srcY = 0.375, dstMapID = 90,   dstX = 0.5, dstY = 0.5, faction = "Horde", name = "Orgrimmar to Undercity",                travelTime = 3, type = "portal" },
    { srcMapID = 85, srcX = 0.465, srcY = 0.372, dstMapID = 110,  dstX = 0.5, dstY = 0.5, faction = "Horde", name = "Orgrimmar to Silvermoon City",          travelTime = 3, type = "portal" },
    -- To expansion hubs
    { srcMapID = 85, srcX = 0.470, srcY = 0.380, dstMapID = 111,  dstX = 0.5, dstY = 0.5, faction = "Horde", name = "Orgrimmar to Shattrath",                travelTime = 3, type = "portal" },
    { srcMapID = 85, srcX = 0.475, srcY = 0.378, dstMapID = 125,  dstX = 0.5, dstY = 0.5, faction = "Horde", name = "Orgrimmar to Dalaran (Northrend)",       travelTime = 3, type = "portal" },
    { srcMapID = 85, srcX = 0.480, srcY = 0.376, dstMapID = 390,  dstX = 0.5, dstY = 0.5, faction = "Horde", name = "Orgrimmar to Vale of Eternal Blossoms",  travelTime = 3, type = "portal" },
    { srcMapID = 85, srcX = 0.485, srcY = 0.374, dstMapID = 588,  dstX = 0.5, dstY = 0.5, faction = "Horde", name = "Orgrimmar to Warspear (Ashran)",         travelTime = 3, type = "portal" },
    { srcMapID = 85, srcX = 0.490, srcY = 0.372, dstMapID = 862,  dstX = 0.5, dstY = 0.5, faction = "Horde", name = "Orgrimmar to Zuldazar",                  travelTime = 3, type = "portal" },
    { srcMapID = 85, srcX = 0.495, srcY = 0.370, dstMapID = 1670, dstX = 0.5, dstY = 0.5, faction = "Horde", name = "Orgrimmar to Oribos",                    travelTime = 3, type = "portal" },
    { srcMapID = 85, srcX = 0.455, srcY = 0.365, dstMapID = 2112, dstX = 0.5, dstY = 0.5, faction = "Horde", name = "Orgrimmar to Valdrakken",                travelTime = 3, type = "portal" },
    { srcMapID = 85, srcX = 0.460, srcY = 0.363, dstMapID = 2339, dstX = 0.5, dstY = 0.5, faction = "Horde", name = "Orgrimmar to Dornogal",                  travelTime = 3, type = "portal" },
    { srcMapID = 85, srcX = 0.465, srcY = 0.361, dstMapID = 2602, dstX = 0.5, dstY = 0.5, faction = "Horde", name = "Orgrimmar to Silvermoon (Midnight)",      travelTime = 3, type = "portal" },

    -----------------------------------------------------------------
    -- STORMWIND PORTAL ROOM (Wizard's Sanctum)
    -----------------------------------------------------------------
    { srcMapID = 84, srcX = 0.490, srcY = 0.870, dstMapID = 87,   dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Stormwind to Ironforge",               travelTime = 3, type = "portal" },
    { srcMapID = 84, srcX = 0.495, srcY = 0.868, dstMapID = 89,   dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Stormwind to Darnassus",               travelTime = 3, type = "portal" },
    { srcMapID = 84, srcX = 0.488, srcY = 0.866, dstMapID = 103,  dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Stormwind to Exodar",                  travelTime = 3, type = "portal" },
    -- To expansion hubs
    { srcMapID = 84, srcX = 0.492, srcY = 0.864, dstMapID = 111,  dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Stormwind to Shattrath",               travelTime = 3, type = "portal" },
    { srcMapID = 84, srcX = 0.494, srcY = 0.862, dstMapID = 125,  dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Stormwind to Dalaran (Northrend)",      travelTime = 3, type = "portal" },
    { srcMapID = 84, srcX = 0.496, srcY = 0.860, dstMapID = 390,  dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Stormwind to Vale of Eternal Blossoms", travelTime = 3, type = "portal" },
    { srcMapID = 84, srcX = 0.498, srcY = 0.858, dstMapID = 588,  dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Stormwind to Stormshield (Ashran)",     travelTime = 3, type = "portal" },
    { srcMapID = 84, srcX = 0.486, srcY = 0.856, dstMapID = 1161, dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Stormwind to Boralus",                  travelTime = 3, type = "portal" },
    { srcMapID = 84, srcX = 0.488, srcY = 0.854, dstMapID = 1670, dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Stormwind to Oribos",                   travelTime = 3, type = "portal" },
    { srcMapID = 84, srcX = 0.490, srcY = 0.852, dstMapID = 2112, dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Stormwind to Valdrakken",               travelTime = 3, type = "portal" },
    { srcMapID = 84, srcX = 0.492, srcY = 0.850, dstMapID = 2339, dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Stormwind to Dornogal",                 travelTime = 3, type = "portal" },
    { srcMapID = 84, srcX = 0.494, srcY = 0.848, dstMapID = 2602, dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Stormwind to Silvermoon (Midnight)",     travelTime = 3, type = "portal" },
    -- Dark Portal
    { srcMapID = 84, srcX = 0.497, srcY = 0.846, dstMapID = 100,  dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Stormwind to Hellfire Peninsula",       travelTime = 3, type = "portal" },

    -----------------------------------------------------------------
    -- DALARAN (BROKEN ISLES) PORTAL ROOM
    -----------------------------------------------------------------
    { srcMapID = 627, srcX = 0.397, srcY = 0.630, dstMapID = 85,   dstX = 0.5, dstY = 0.5, faction = "Horde",    name = "Dalaran to Orgrimmar",          travelTime = 3, type = "portal" },
    { srcMapID = 627, srcX = 0.400, srcY = 0.628, dstMapID = 84,   dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Dalaran to Stormwind",          travelTime = 3, type = "portal" },
    { srcMapID = 627, srcX = 0.403, srcY = 0.626, dstMapID = 198,  dstX = 0.5, dstY = 0.5, faction = "Both",     name = "Dalaran to Wyrmrest Temple",    travelTime = 3, type = "portal" },
    { srcMapID = 627, srcX = 0.406, srcY = 0.624, dstMapID = 646,  dstX = 0.5, dstY = 0.5, faction = "Both",     name = "Dalaran to Broken Shore",       travelTime = 3, type = "portal" },
    { srcMapID = 627, srcX = 0.409, srcY = 0.622, dstMapID = 81,   dstX = 0.5, dstY = 0.5, faction = "Both",     name = "Dalaran to Caverns of Time",    travelTime = 3, type = "portal" },
    { srcMapID = 627, srcX = 0.412, srcY = 0.620, dstMapID = 111,  dstX = 0.5, dstY = 0.5, faction = "Both",     name = "Dalaran to Shattrath",          travelTime = 3, type = "portal" },

    -----------------------------------------------------------------
    -- VALDRAKKEN PORTALS (Dragon Isles Hub)
    -----------------------------------------------------------------
    { srcMapID = 2112, srcX = 0.585, srcY = 0.353, dstMapID = 85,   dstX = 0.5, dstY = 0.5, faction = "Horde",    name = "Valdrakken to Orgrimmar",       travelTime = 3, type = "portal" },
    { srcMapID = 2112, srcX = 0.588, srcY = 0.351, dstMapID = 84,   dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Valdrakken to Stormwind",       travelTime = 3, type = "portal" },
    { srcMapID = 2112, srcX = 0.591, srcY = 0.349, dstMapID = 2339, dstX = 0.5, dstY = 0.5, faction = "Both",     name = "Valdrakken to Dornogal",        travelTime = 3, type = "portal" },
    { srcMapID = 2112, srcX = 0.594, srcY = 0.347, dstMapID = 2602, dstX = 0.5, dstY = 0.5, faction = "Both",     name = "Valdrakken to Silvermoon (Midnight)", travelTime = 3, type = "portal" },

    -----------------------------------------------------------------
    -- DORNOGAL PORTALS (Khaz Algar Hub)
    -----------------------------------------------------------------
    { srcMapID = 2339, srcX = 0.442, srcY = 0.550, dstMapID = 85,   dstX = 0.5, dstY = 0.5, faction = "Horde",    name = "Dornogal to Orgrimmar",         travelTime = 3, type = "portal" },
    { srcMapID = 2339, srcX = 0.445, srcY = 0.548, dstMapID = 84,   dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Dornogal to Stormwind",         travelTime = 3, type = "portal" },
    { srcMapID = 2339, srcX = 0.448, srcY = 0.546, dstMapID = 2112, dstX = 0.5, dstY = 0.5, faction = "Both",     name = "Dornogal to Valdrakken",        travelTime = 3, type = "portal" },
    { srcMapID = 2339, srcX = 0.451, srcY = 0.544, dstMapID = 2602, dstX = 0.5, dstY = 0.5, faction = "Both",     name = "Dornogal to Silvermoon (Midnight)", travelTime = 3, type = "portal" },

    -----------------------------------------------------------------
    -- ORIBOS PORTALS (Shadowlands Hub)
    -----------------------------------------------------------------
    { srcMapID = 1670, srcX = 0.209, srcY = 0.570, dstMapID = 85,   dstX = 0.5, dstY = 0.5, faction = "Horde",    name = "Oribos to Orgrimmar",           travelTime = 3, type = "portal" },
    { srcMapID = 1670, srcX = 0.212, srcY = 0.568, dstMapID = 84,   dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Oribos to Stormwind",           travelTime = 3, type = "portal" },
    { srcMapID = 1670, srcX = 0.215, srcY = 0.566, dstMapID = 1533, dstX = 0.5, dstY = 0.5, faction = "Both",     name = "Oribos to Bastion",             travelTime = 3, type = "portal" },
    { srcMapID = 1670, srcX = 0.218, srcY = 0.564, dstMapID = 1536, dstX = 0.5, dstY = 0.5, faction = "Both",     name = "Oribos to Maldraxxus",          travelTime = 3, type = "portal" },
    { srcMapID = 1670, srcX = 0.221, srcY = 0.562, dstMapID = 1565, dstX = 0.5, dstY = 0.5, faction = "Both",     name = "Oribos to Ardenweald",          travelTime = 3, type = "portal" },
    { srcMapID = 1670, srcX = 0.224, srcY = 0.560, dstMapID = 1525, dstX = 0.5, dstY = 0.5, faction = "Both",     name = "Oribos to Revendreth",          travelTime = 3, type = "portal" },
    { srcMapID = 1670, srcX = 0.227, srcY = 0.558, dstMapID = 1961, dstX = 0.5, dstY = 0.5, faction = "Both",     name = "Oribos to Korthia",             travelTime = 3, type = "portal" },
    { srcMapID = 1670, srcX = 0.230, srcY = 0.556, dstMapID = 1970, dstX = 0.5, dstY = 0.5, faction = "Both",     name = "Oribos to Zereth Mortis",       travelTime = 3, type = "portal" },

    -----------------------------------------------------------------
    -- MIDNIGHT SILVERMOON PORTALS
    -----------------------------------------------------------------
    { srcMapID = 2602, srcX = 0.500, srcY = 0.350, dstMapID = 85,   dstX = 0.5, dstY = 0.5, faction = "Horde",    name = "Silvermoon (Midnight) to Orgrimmar",  travelTime = 3, type = "portal" },
    { srcMapID = 2602, srcX = 0.503, srcY = 0.348, dstMapID = 84,   dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Silvermoon (Midnight) to Stormwind",  travelTime = 3, type = "portal" },
    { srcMapID = 2602, srcX = 0.506, srcY = 0.346, dstMapID = 2339, dstX = 0.5, dstY = 0.5, faction = "Both",     name = "Silvermoon (Midnight) to Dornogal",   travelTime = 3, type = "portal" },
    { srcMapID = 2602, srcX = 0.509, srcY = 0.344, dstMapID = 2112, dstX = 0.5, dstY = 0.5, faction = "Both",     name = "Silvermoon (Midnight) to Valdrakken", travelTime = 3, type = "portal" },
    { srcMapID = 2602, srcX = 0.512, srcY = 0.342, dstMapID = 627,  dstX = 0.5, dstY = 0.5, faction = "Both",     name = "Silvermoon (Midnight) to Dalaran",    travelTime = 3, type = "portal" },

    -----------------------------------------------------------------
    -- RETURN PORTALS (expansion hubs back to capitals)
    -----------------------------------------------------------------
    -- Shattrath
    { srcMapID = 111, srcX = 0.572, srcY = 0.482, dstMapID = 85,  dstX = 0.5, dstY = 0.5, faction = "Horde",    name = "Shattrath to Orgrimmar",     travelTime = 3, type = "portal" },
    { srcMapID = 111, srcX = 0.575, srcY = 0.480, dstMapID = 84,  dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Shattrath to Stormwind",     travelTime = 3, type = "portal" },

    -- Dalaran (Northrend)
    { srcMapID = 125, srcX = 0.400, srcY = 0.630, dstMapID = 85,  dstX = 0.5, dstY = 0.5, faction = "Horde",    name = "Dalaran (N) to Orgrimmar",   travelTime = 3, type = "portal" },
    { srcMapID = 125, srcX = 0.403, srcY = 0.628, dstMapID = 84,  dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Dalaran (N) to Stormwind",   travelTime = 3, type = "portal" },

    -----------------------------------------------------------------
    -- BOATS & ZEPPELINS
    -----------------------------------------------------------------
    -- Orgrimmar <-> Undercity (Zeppelin)
    { srcMapID = 85,  srcX = 0.534, srcY = 0.528, dstMapID = 90,  dstX = 0.5, dstY = 0.5, faction = "Horde", name = "Orgrimmar Zeppelin to Undercity",   travelTime = 60, type = "zeppelin" },
    { srcMapID = 90,  srcX = 0.608, srcY = 0.586, dstMapID = 85,  dstX = 0.5, dstY = 0.5, faction = "Horde", name = "Undercity Zeppelin to Orgrimmar",   travelTime = 60, type = "zeppelin" },

    -- Orgrimmar <-> Borean Tundra (Zeppelin)
    { srcMapID = 85,  srcX = 0.534, srcY = 0.528, dstMapID = 114, dstX = 0.5, dstY = 0.5, faction = "Horde", name = "Orgrimmar Zeppelin to Borean Tundra", travelTime = 60, type = "zeppelin" },

    -- Stormwind <-> Borean Tundra (Boat)
    { srcMapID = 84,  srcX = 0.202, srcY = 0.560, dstMapID = 114, dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Stormwind Boat to Borean Tundra", travelTime = 60, type = "boat" },

    -- Stormwind <-> Darnassus (Boat via Rut'theran)
    { srcMapID = 84,  srcX = 0.202, srcY = 0.560, dstMapID = 89,  dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Stormwind Boat to Darnassus",     travelTime = 60, type = "boat" },

    -- Ironforge <-> Stormwind (Deeprun Tram)
    { srcMapID = 87,  srcX = 0.726, srcY = 0.500, dstMapID = 84,  dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Deeprun Tram to Stormwind",       travelTime = 30, type = "tram" },
    { srcMapID = 84,  srcX = 0.640, srcY = 0.080, dstMapID = 87,  dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Deeprun Tram to Ironforge",       travelTime = 30, type = "tram" },

    -----------------------------------------------------------------
    -- DARK PORTAL
    -----------------------------------------------------------------
    { srcMapID = 17,  srcX = 0.543, srcY = 0.420, dstMapID = 100, dstX = 0.5, dstY = 0.5, faction = "Both", name = "Dark Portal to Hellfire Peninsula",    travelTime = 3, type = "portal" },
    { srcMapID = 100, srcX = 0.892, srcY = 0.503, dstMapID = 17,  dstX = 0.5, dstY = 0.5, faction = "Both", name = "Dark Portal to Blasted Lands",         travelTime = 3, type = "portal" },

    -----------------------------------------------------------------
    -- CAVERNS OF TIME (Tanaris)
    -----------------------------------------------------------------
    { srcMapID = 71,  srcX = 0.649, srcY = 0.498, dstMapID = 84,  dstX = 0.5, dstY = 0.5, faction = "Alliance", name = "Caverns of Time to Stormwind",    travelTime = 3, type = "portal" },
    { srcMapID = 71,  srcX = 0.652, srcY = 0.496, dstMapID = 85,  dstX = 0.5, dstY = 0.5, faction = "Horde",    name = "Caverns of Time to Orgrimmar",    travelTime = 3, type = "portal" },
}
