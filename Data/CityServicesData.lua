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
