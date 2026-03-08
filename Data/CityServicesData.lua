------------------------------------------------------------------------
-- DestinationXD - CityServicesData.lua
-- City services & POI data for quick navigation (like guards but better)
-- Also includes Mythic+ Season 1 dungeon entrances
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

------------------------------------------------------------------------
-- CITY SERVICES: Navigate to common services within major cities
-- Structure: cityMapID -> { services }
-- Each service has: name, type, mapID, x, y (map coordinates 0-1)
------------------------------------------------------------------------
DXD.CityServices = {
    -- =========================================================
    -- DORNOGAL (The War Within Capital)
    -- =========================================================
    [2339] = {
        cityName = "Dornogal",
        services = {
            { name = "Auction House",     type = "auction",    x = 0.548, y = 0.604 },
            { name = "Bank",              type = "bank",       x = 0.558, y = 0.562 },
            { name = "Barber Shop",        type = "barber",     x = 0.472, y = 0.535 },
            { name = "Flight Master",     type = "flight",     x = 0.580, y = 0.644 },
            { name = "Inn",               type = "inn",        x = 0.535, y = 0.535 },
            { name = "Mailbox",           type = "mail",       x = 0.552, y = 0.598 },
            { name = "Portal Room",       type = "portal",     x = 0.475, y = 0.467 },
            { name = "Profession Trainers", type = "profession", x = 0.551, y = 0.494 },
            { name = "Repair Vendor",     type = "repair",     x = 0.525, y = 0.570 },
            { name = "Stable Master",     type = "stable",     x = 0.563, y = 0.653 },
            { name = "Transmogrifier",    type = "transmog",   x = 0.470, y = 0.540 },
            { name = "Void Storage",      type = "void",       x = 0.470, y = 0.545 },
            { name = "Guild Bank",        type = "guildbank",  x = 0.558, y = 0.558 },
        },
    },

    -- =========================================================
    -- STORMWIND
    -- =========================================================
    [84] = {
        cityName = "Stormwind City",
        services = {
            { name = "Auction House",     type = "auction",    x = 0.616, y = 0.706 },
            { name = "Bank",              type = "bank",       x = 0.633, y = 0.686 },
            { name = "Barber Shop",        type = "barber",     x = 0.614, y = 0.675 },
            { name = "Flight Master",     type = "flight",     x = 0.710, y = 0.725 },
            { name = "Inn",               type = "inn",        x = 0.606, y = 0.682 },
            { name = "Mailbox",           type = "mail",       x = 0.618, y = 0.700 },
            { name = "Portal Room",       type = "portal",     x = 0.491, y = 0.873 },
            { name = "Profession Trainers", type = "profession", x = 0.567, y = 0.590 },
            { name = "Repair Vendor",     type = "repair",     x = 0.622, y = 0.714 },
            { name = "Stable Master",     type = "stable",     x = 0.715, y = 0.745 },
            { name = "Transmogrifier",    type = "transmog",   x = 0.607, y = 0.680 },
            { name = "Void Storage",      type = "void",       x = 0.607, y = 0.685 },
        },
    },

    -- =========================================================
    -- ORGRIMMAR
    -- =========================================================
    [85] = {
        cityName = "Orgrimmar",
        services = {
            { name = "Auction House",     type = "auction",    x = 0.547, y = 0.730 },
            { name = "Bank",              type = "bank",       x = 0.485, y = 0.670 },
            { name = "Barber Shop",        type = "barber",     x = 0.441, y = 0.535 },
            { name = "Flight Master",     type = "flight",     x = 0.494, y = 0.618 },
            { name = "Inn",               type = "inn",        x = 0.534, y = 0.686 },
            { name = "Mailbox",           type = "mail",       x = 0.547, y = 0.726 },
            { name = "Portal Room",       type = "portal",     x = 0.550, y = 0.340 },
            { name = "Profession Trainers", type = "profession", x = 0.454, y = 0.580 },
            { name = "Repair Vendor",     type = "repair",     x = 0.498, y = 0.682 },
            { name = "Stable Master",     type = "stable",     x = 0.505, y = 0.620 },
            { name = "Transmogrifier",    type = "transmog",   x = 0.443, y = 0.531 },
            { name = "Void Storage",      type = "void",       x = 0.443, y = 0.527 },
        },
    },

    -- =========================================================
    -- VALDRAKKEN (Dragon Isles)
    -- =========================================================
    [2112] = {
        cityName = "Valdrakken",
        services = {
            { name = "Auction House",     type = "auction",    x = 0.352, y = 0.637 },
            { name = "Bank",              type = "bank",       x = 0.360, y = 0.620 },
            { name = "Barber Shop",        type = "barber",     x = 0.407, y = 0.452 },
            { name = "Flight Master",     type = "flight",     x = 0.472, y = 0.522 },
            { name = "Inn",               type = "inn",        x = 0.424, y = 0.465 },
            { name = "Mailbox",           type = "mail",       x = 0.352, y = 0.640 },
            { name = "Portal Room",       type = "portal",     x = 0.267, y = 0.584 },
            { name = "Profession Trainers", type = "profession", x = 0.354, y = 0.625 },
            { name = "Repair Vendor",     type = "repair",     x = 0.380, y = 0.598 },
            { name = "Transmogrifier",    type = "transmog",   x = 0.405, y = 0.448 },
            { name = "Void Storage",      type = "void",       x = 0.410, y = 0.450 },
        },
    },

    -- =========================================================
    -- ORIBOS (Shadowlands)
    -- =========================================================
    [1670] = {
        cityName = "Oribos",
        services = {
            { name = "Auction House",     type = "auction",    x = 0.591, y = 0.266 },
            { name = "Bank",              type = "bank",       x = 0.504, y = 0.440 },
            { name = "Flight Master",     type = "flight",     x = 0.604, y = 0.688 },
            { name = "Inn",               type = "inn",        x = 0.606, y = 0.422 },
            { name = "Mailbox",           type = "mail",       x = 0.510, y = 0.438 },
            { name = "Portal Room",       type = "portal",     x = 0.241, y = 0.548 },
            { name = "Repair Vendor",     type = "repair",     x = 0.522, y = 0.486 },
            { name = "Transmogrifier",    type = "transmog",   x = 0.506, y = 0.444 },
        },
    },

    -- =========================================================
    -- DALARAN (Broken Isles)
    -- =========================================================
    [627] = {
        cityName = "Dalaran",
        services = {
            { name = "Auction House",     type = "auction",    x = 0.585, y = 0.318 },
            { name = "Bank",              type = "bank",       x = 0.542, y = 0.390 },
            { name = "Barber Shop",        type = "barber",     x = 0.512, y = 0.306 },
            { name = "Flight Master",     type = "flight",     x = 0.698, y = 0.510 },
            { name = "Inn",               type = "inn",        x = 0.506, y = 0.372 },
            { name = "Mailbox",           type = "mail",       x = 0.545, y = 0.386 },
            { name = "Portal Room",       type = "portal",     x = 0.286, y = 0.490 },
            { name = "Repair Vendor",     type = "repair",     x = 0.530, y = 0.362 },
            { name = "Transmogrifier",    type = "transmog",   x = 0.504, y = 0.306 },
        },
    },

    -- =========================================================
    -- SILVERMOON CITY (Midnight - Renewed)
    -- =========================================================
    [2602] = {
        cityName = "Silvermoon City",
        services = {
            { name = "Auction House",     type = "auction",    x = 0.542, y = 0.533 },
            { name = "Bank",              type = "bank",       x = 0.535, y = 0.516 },
            { name = "Barber Shop",        type = "barber",     x = 0.521, y = 0.554 },
            { name = "Flight Master",     type = "flight",     x = 0.533, y = 0.343 },
            { name = "Inn",               type = "inn",        x = 0.578, y = 0.516 },
            { name = "Mailbox",           type = "mail",       x = 0.540, y = 0.530 },
            { name = "Portal Room",       type = "portal",     x = 0.498, y = 0.348 },
            { name = "Profession Trainers", type = "profession", x = 0.558, y = 0.554 },
            { name = "Repair Vendor",     type = "repair",     x = 0.562, y = 0.530 },
            { name = "Stable Master",     type = "stable",     x = 0.530, y = 0.340 },
            { name = "Transmogrifier",    type = "transmog",   x = 0.519, y = 0.558 },
            { name = "Void Storage",      type = "void",       x = 0.517, y = 0.562 },
            { name = "Guild Bank",        type = "guildbank",  x = 0.537, y = 0.518 },
            { name = "Timeways Portal",   type = "portal",     x = 0.533, y = 0.661 },
        },
    },

    -- =========================================================
    -- IRONFORGE
    -- =========================================================
    [87] = {
        cityName = "Ironforge",
        services = {
            { name = "Auction House",     type = "auction",    x = 0.258, y = 0.745 },
            { name = "Bank",              type = "bank",       x = 0.355, y = 0.607 },
            { name = "Barber Shop",        type = "barber",     x = 0.476, y = 0.892 },
            { name = "Flight Master",     type = "flight",     x = 0.558, y = 0.480 },
            { name = "Inn",               type = "inn",        x = 0.183, y = 0.515 },
            { name = "Mailbox",           type = "mail",       x = 0.266, y = 0.749 },
            { name = "Repair Vendor",     type = "repair",     x = 0.441, y = 0.894 },
            { name = "Profession Trainers", type = "profession", x = 0.430, y = 0.845 },
            { name = "Transmogrifier",    type = "transmog",   x = 0.476, y = 0.890 },
        },
    },

    -- =========================================================
    -- THUNDER BLUFF
    -- =========================================================
    [88] = {
        cityName = "Thunder Bluff",
        services = {
            { name = "Auction House",     type = "auction",    x = 0.448, y = 0.574 },
            { name = "Bank",              type = "bank",       x = 0.463, y = 0.462 },
            { name = "Flight Master",     type = "flight",     x = 0.470, y = 0.499 },
            { name = "Inn",               type = "inn",        x = 0.455, y = 0.464 },
            { name = "Mailbox",           type = "mail",       x = 0.453, y = 0.570 },
            { name = "Repair Vendor",     type = "repair",     x = 0.444, y = 0.570 },
            { name = "Profession Trainers", type = "profession", x = 0.393, y = 0.368 },
        },
    },

    -- =========================================================
    -- BORALUS (BFA Alliance Hub)
    -- =========================================================
    [1161] = {
        cityName = "Boralus",
        services = {
            { name = "Auction House",     type = "auction",    x = 0.565, y = 0.494 },
            { name = "Bank",              type = "bank",       x = 0.590, y = 0.520 },
            { name = "Barber Shop",        type = "barber",     x = 0.577, y = 0.477 },
            { name = "Flight Master",     type = "flight",     x = 0.688, y = 0.548 },
            { name = "Inn",               type = "inn",        x = 0.739, y = 0.579 },
            { name = "Mailbox",           type = "mail",       x = 0.567, y = 0.496 },
            { name = "Portal Room",       type = "portal",     x = 0.702, y = 0.262 },
            { name = "Repair Vendor",     type = "repair",     x = 0.585, y = 0.516 },
            { name = "Transmogrifier",    type = "transmog",   x = 0.577, y = 0.473 },
        },
    },

    -- =========================================================
    -- DAZAR'ALOR (BFA Horde Hub)
    -- =========================================================
    [1165] = {
        cityName = "Dazar'alor",
        services = {
            { name = "Auction House",     type = "auction",    x = 0.420, y = 0.334 },
            { name = "Bank",              type = "bank",       x = 0.448, y = 0.128 },
            { name = "Barber Shop",        type = "barber",     x = 0.422, y = 0.372 },
            { name = "Flight Master",     type = "flight",     x = 0.512, y = 0.414 },
            { name = "Inn",               type = "inn",        x = 0.484, y = 0.281 },
            { name = "Mailbox",           type = "mail",       x = 0.418, y = 0.338 },
            { name = "Portal Room",       type = "portal",     x = 0.502, y = 0.152 },
            { name = "Repair Vendor",     type = "repair",     x = 0.432, y = 0.340 },
            { name = "Transmogrifier",    type = "transmog",   x = 0.424, y = 0.376 },
        },
    },
}

------------------------------------------------------------------------
-- CITY MAP ID ALIASES
-- WoW sometimes returns sub-zone map IDs instead of the city map ID.
-- This maps sub-zone IDs to their parent city so services still display.
------------------------------------------------------------------------
DXD.CityMapAliases = {
    -- Silvermoon (Midnight) - ALL possible sub-floor/sub-zone/parent maps
    -- WoW may return any of these when the player is inside the city
    [2601] = 2602,  -- Quel'Thalas continent map -> Silvermoon
    [2603] = 2602,  -- Eversong Woods (Renewed) -> Silvermoon
    [2604] = 2602,  -- Ghostlands (Renewed) -> Silvermoon
    [2605] = 2602,  -- Sunwell Plateau -> Silvermoon
    [2606] = 2602,  -- Isle of Quel'Danas -> Silvermoon
    [2607] = 2602,  -- Thalassian Pass -> Silvermoon
    [2608] = 2602,  -- Sunstrider Isle -> Silvermoon
    [2609] = 2602,  -- The Dead Scar -> Silvermoon
    [110]  = 2602,  -- Old Silvermoon City -> Renewed Silvermoon

    -- Stormwind sub-zones
    [1453] = 84,    -- Stormwind sub-map

    -- Orgrimmar sub-zones
    [86]   = 85,    -- Orgrimmar (Cleft of Shadow variant)

    -- Dalaran sub-zones
    [628]  = 627,   -- Dalaran - The Underbelly
    [629]  = 627,   -- Dalaran sub-zone

    -- Oribos sub-zones
    [1671] = 1670,  -- Ring of Fates
    [1672] = 1670,  -- Ring of Transference
    [1673] = 1670,  -- Broker's Den

    -- Dornogal sub-zones
    [2340] = 2339,  -- City of Threads approach

    -- Boralus sub-zones
    [1162] = 1161,  -- Boralus sub-map

    -- Valdrakken sub-zones
    [2113] = 2112,  -- Valdrakken interior
    [2114] = 2112,  -- Valdrakken sub-floor

    -- Dazar'alor sub-zones
    [1163] = 1165,  -- Dazar'alor interior
    [1164] = 1165,  -- Dazar'alor floor
    [1352] = 1165,  -- Dazar'alor floor 2
}

------------------------------------------------------------------------
-- MYTHIC+ DUNGEONS (Season 1 - Midnight Expansion)
-- Correct rotation: 4 new Midnight + 4 returning legacy
-- Legacy dungeons accessed via Timeways portal in Silvermoon (53.3, 66.1)
------------------------------------------------------------------------
DXD.MythicPlusDungeons = {
    season = "Midnight Season 1",
    dungeons = {
        -- === NEW MIDNIGHT DUNGEONS ===
        {
            name = "Windrunner Spire",
            entranceMapID = 2603,  -- Eversong Woods (Renewed)
            entranceX = 0.355,
            entranceY = 0.788,
            keyLevel = "M+",
            new = true,
        },
        {
            name = "Magister's Terrace",
            entranceMapID = 2606,  -- Isle of Quel'Danas
            entranceX = 0.617,
            entranceY = 0.307,
            keyLevel = "M+",
            new = true,
        },
        {
            name = "Maisara Caverns",
            entranceMapID = 2603,  -- Eversong Woods (Renewed) / Zul'Aman area
            entranceX = 0.439,
            entranceY = 0.397,
            keyLevel = "M+",
            new = true,
        },
        {
            name = "Nexus Point Xenas",
            entranceMapID = 2603,  -- Voidstorm / Eversong area
            entranceX = 0.650,
            entranceY = 0.617,
            keyLevel = "M+",
            new = true,
        },
        -- === RETURNING LEGACY DUNGEONS (via Timeways portal in Silvermoon 53.3, 66.1) ===
        {
            name = "Algeth'ar Academy",
            entranceMapID = 2602,  -- Access via Timeways in Silvermoon
            entranceX = 0.533,
            entranceY = 0.661,
            keyLevel = "M+",
            legacy = true,
            timewaysAccess = true,
        },
        {
            name = "Seat of the Triumvirate",
            entranceMapID = 2602,  -- Access via Timeways in Silvermoon
            entranceX = 0.533,
            entranceY = 0.661,
            keyLevel = "M+",
            legacy = true,
            timewaysAccess = true,
        },
        {
            name = "Skyreach",
            entranceMapID = 2602,  -- Access via Timeways in Silvermoon
            entranceX = 0.533,
            entranceY = 0.661,
            keyLevel = "M+",
            legacy = true,
            timewaysAccess = true,
        },
        {
            name = "Pit of Saron",
            entranceMapID = 2602,  -- Access via Timeways in Silvermoon
            entranceX = 0.533,
            entranceY = 0.661,
            keyLevel = "M+",
            legacy = true,
            timewaysAccess = true,
        },
    },
}

------------------------------------------------------------------------
-- SERVICE TYPE DISPLAY INFO
------------------------------------------------------------------------
DXD.ServiceIcons = {
    auction    = { label = "Auction House",    color = { r = 1.0, g = 0.84, b = 0.0 } },
    bank       = { label = "Bank",             color = { r = 0.9, g = 0.75, b = 0.3 } },
    barber     = { label = "Barber Shop",       color = { r = 0.65, g = 0.85, b = 0.95 } },
    flight     = { label = "Flight Master",    color = { r = 0.27, g = 1.0, b = 0.53 } },
    inn        = { label = "Inn",              color = { r = 0.95, g = 0.65, b = 0.35 } },
    mail       = { label = "Mailbox",          color = { r = 0.7, g = 0.7, b = 0.8 } },
    portal     = { label = "Portal Room",      color = { r = 0.6, g = 0.4, b = 1.0 } },
    profession = { label = "Profession Trainers", color = { r = 0.5, g = 0.85, b = 0.5 } },
    repair     = { label = "Repair Vendor",    color = { r = 0.8, g = 0.65, b = 0.5 } },
    stable     = { label = "Stable Master",    color = { r = 0.6, g = 0.8, b = 0.5 } },
    transmog   = { label = "Transmogrifier",   color = { r = 0.85, g = 0.55, b = 0.85 } },
    void       = { label = "Void Storage",     color = { r = 0.5, g = 0.3, b = 0.8 } },
    guildbank  = { label = "Guild Bank",       color = { r = 0.9, g = 0.8, b = 0.3 } },
}
