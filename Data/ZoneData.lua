------------------------------------------------------------------------
-- DestinationXD - ZoneData.lua
-- Complete zone hierarchy for Travel Planner browser
-- Continent -> Zone -> Subzone with map IDs
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

DXD.ZoneData = {
    -----------------------------------------------------------------
    -- EASTERN KINGDOMS
    -----------------------------------------------------------------
    ["Eastern Kingdoms"] = {
        continent = true,
        mapID = 13,
        children = {
            ["Stormwind City"]     = { mapID = 84,  faction = "Alliance", capital = true },
            ["Ironforge"]          = { mapID = 87,  faction = "Alliance", capital = true },
            ["Undercity"]          = { mapID = 90,  faction = "Horde",    capital = true },
            ["Silvermoon City"]    = { mapID = 110, faction = "Horde",    capital = true },
            ["Elwynn Forest"]      = { mapID = 37,  faction = "Alliance" },
            ["Westfall"]           = { mapID = 52,  faction = "Alliance" },
            ["Redridge Mountains"] = { mapID = 49,  faction = "Alliance" },
            ["Duskwood"]           = { mapID = 47,  faction = "Alliance" },
            ["Stranglethorn Vale"] = { mapID = 224, faction = "Both" },
            ["Northern Stranglethorn"] = { mapID = 50, faction = "Both" },
            ["The Cape of Stranglethorn"] = { mapID = 210, faction = "Both" },
            ["Swamp of Sorrows"]   = { mapID = 51,  faction = "Both" },
            ["Blasted Lands"]      = { mapID = 17,  faction = "Both" },
            ["Burning Steppes"]    = { mapID = 36,  faction = "Both" },
            ["Searing Gorge"]      = { mapID = 32,  faction = "Both" },
            ["Badlands"]           = { mapID = 15,  faction = "Both" },
            ["Loch Modan"]         = { mapID = 48,  faction = "Alliance" },
            ["Dun Morogh"]         = { mapID = 27,  faction = "Alliance" },
            ["Wetlands"]           = { mapID = 56,  faction = "Alliance" },
            ["Arathi Highlands"]   = { mapID = 14,  faction = "Both" },
            ["Hillsbrad Foothills"] = { mapID = 25,  faction = "Both" },
            ["The Hinterlands"]    = { mapID = 26,  faction = "Both" },
            ["Western Plaguelands"] = { mapID = 22,  faction = "Both" },
            ["Eastern Plaguelands"] = { mapID = 23,  faction = "Both" },
            ["Tirisfal Glades"]    = { mapID = 18,  faction = "Horde" },
            ["Silverpine Forest"]  = { mapID = 21,  faction = "Horde" },
            ["Eversong Woods"]     = { mapID = 94,  faction = "Horde" },
            ["Ghostlands"]         = { mapID = 95,  faction = "Horde" },
            ["Deadwind Pass"]      = { mapID = 42,  faction = "Both" },
            ["Twilight Highlands"] = { mapID = 241, faction = "Both" },
            ["Gilneas"]            = { mapID = 217, faction = "Alliance" },
            -- Dungeons
            ["The Deadmines"]      = { mapID = 291, faction = "Both", dungeon = true },
            ["Shadowfang Keep"]    = { mapID = 310, faction = "Both", dungeon = true },
            ["The Stockade"]       = { mapID = 225, faction = "Alliance", dungeon = true },
            ["Gnomeregan"]         = { mapID = 226, faction = "Both", dungeon = true },
            ["Scarlet Monastery"]  = { mapID = 302, faction = "Both", dungeon = true },
            ["Scholomance"]        = { mapID = 476, faction = "Both", dungeon = true },
            ["Stratholme"]         = { mapID = 317, faction = "Both", dungeon = true },
            ["Blackrock Depths"]   = { mapID = 242, faction = "Both", dungeon = true },
            ["Blackrock Spire"]    = { mapID = 250, faction = "Both", dungeon = true },
            ["Sunken Temple"]      = { mapID = 220, faction = "Both", dungeon = true },
            ["Zul'Gurub"]          = { mapID = 337, faction = "Both", dungeon = true },
            ["Karazhan"]           = { mapID = 350, faction = "Both", dungeon = true },
        },
    },

    -----------------------------------------------------------------
    -- KALIMDOR
    -----------------------------------------------------------------
    ["Kalimdor"] = {
        continent = true,
        mapID = 12,
        children = {
            ["Orgrimmar"]          = { mapID = 85,  faction = "Horde",    capital = true },
            ["Thunder Bluff"]      = { mapID = 88,  faction = "Horde",    capital = true },
            ["Darnassus"]          = { mapID = 89,  faction = "Alliance", capital = true },
            ["Exodar"]             = { mapID = 103, faction = "Alliance", capital = true },
            ["Durotar"]            = { mapID = 1,   faction = "Horde" },
            ["Mulgore"]            = { mapID = 7,   faction = "Horde" },
            ["Northern Barrens"]   = { mapID = 10,  faction = "Both" },
            ["Southern Barrens"]   = { mapID = 199, faction = "Both" },
            ["Ashenvale"]          = { mapID = 63,  faction = "Both" },
            ["Stonetalon Mountains"] = { mapID = 65, faction = "Both" },
            ["Desolace"]           = { mapID = 66,  faction = "Both" },
            ["Feralas"]            = { mapID = 69,  faction = "Both" },
            ["Thousand Needles"]   = { mapID = 64,  faction = "Both" },
            ["Dustwallow Marsh"]   = { mapID = 70,  faction = "Both" },
            ["Tanaris"]            = { mapID = 71,  faction = "Both" },
            ["Un'Goro Crater"]     = { mapID = 78,  faction = "Both" },
            ["Silithus"]           = { mapID = 81,  faction = "Both" },
            ["Felwood"]            = { mapID = 77,  faction = "Both" },
            ["Winterspring"]       = { mapID = 83,  faction = "Both" },
            ["Moonglade"]          = { mapID = 80,  faction = "Both" },
            ["Mount Hyjal"]        = { mapID = 198, faction = "Both" },
            ["Darkshore"]          = { mapID = 62,  faction = "Alliance" },
            ["Teldrassil"]         = { mapID = 57,  faction = "Alliance" },
            ["Azshara"]            = { mapID = 76,  faction = "Horde" },
            ["Azuremyst Isle"]     = { mapID = 97,  faction = "Alliance" },
            ["Bloodmyst Isle"]     = { mapID = 106, faction = "Alliance" },
            ["Uldum"]              = { mapID = 249, faction = "Both" },
            -- Dungeons
            ["Ragefire Chasm"]     = { mapID = 213, faction = "Horde", dungeon = true },
            ["Wailing Caverns"]    = { mapID = 279, faction = "Both", dungeon = true },
            ["Blackfathom Deeps"]  = { mapID = 221, faction = "Both", dungeon = true },
            ["Razorfen Kraul"]     = { mapID = 301, faction = "Both", dungeon = true },
            ["Razorfen Downs"]     = { mapID = 300, faction = "Both", dungeon = true },
            ["Maraudon"]           = { mapID = 280, faction = "Both", dungeon = true },
            ["Dire Maul"]          = { mapID = 234, faction = "Both", dungeon = true },
            ["Zul'Farrak"]         = { mapID = 219, faction = "Both", dungeon = true },
            ["Ahn'Qiraj"]          = { mapID = 319, faction = "Both", dungeon = true },
        },
    },

    -----------------------------------------------------------------
    -- QUEL'THALAS (MIDNIGHT EXPANSION)
    -----------------------------------------------------------------
    ["Quel'Thalas"] = {
        continent = true,
        mapID = 2601, -- Placeholder for Midnight continent
        children = {
            ["Silvermoon City (Renewed)"]  = { mapID = 2602, faction = "Both", midnight = true },
            ["Eversong Woods (Renewed)"]   = { mapID = 2603, faction = "Both", midnight = true },
            ["Ghostlands (Renewed)"]       = { mapID = 2604, faction = "Both", midnight = true },
            ["The Sunwell Plateau"]        = { mapID = 2605, faction = "Both", midnight = true },
            ["Isle of Quel'Danas"]         = { mapID = 2606, faction = "Both", midnight = true },
            ["The Thalassian Pass"]        = { mapID = 2607, faction = "Both", midnight = true },
            ["Sunstrider Isle"]            = { mapID = 2608, faction = "Both", midnight = true },
            ["The Dead Scar"]              = { mapID = 2609, faction = "Both", midnight = true },
        },
    },

    -----------------------------------------------------------------
    -- NORTHREND
    -----------------------------------------------------------------
    ["Northrend"] = {
        continent = true,
        mapID = 113,
        children = {
            ["Dalaran (Northrend)"]  = { mapID = 125, faction = "Both", capital = true },
            ["Borean Tundra"]        = { mapID = 114, faction = "Both" },
            ["Howling Fjord"]        = { mapID = 117, faction = "Both" },
            ["Dragonblight"]         = { mapID = 115, faction = "Both" },
            ["Grizzly Hills"]        = { mapID = 116, faction = "Both" },
            ["Zul'Drak"]             = { mapID = 121, faction = "Both" },
            ["Sholazar Basin"]       = { mapID = 119, faction = "Both" },
            ["The Storm Peaks"]      = { mapID = 120, faction = "Both" },
            ["Icecrown"]             = { mapID = 118, faction = "Both" },
            ["Crystalsong Forest"]   = { mapID = 127, faction = "Both" },
            ["Wintergrasp"]          = { mapID = 123, faction = "Both" },
            -- Dungeons
            ["Utgarde Keep"]         = { mapID = 133, faction = "Both", dungeon = true },
            ["The Nexus"]            = { mapID = 129, faction = "Both", dungeon = true },
            ["Azjol-Nerub"]          = { mapID = 157, faction = "Both", dungeon = true },
            ["Drak'Tharon Keep"]     = { mapID = 160, faction = "Both", dungeon = true },
            ["Halls of Stone"]       = { mapID = 140, faction = "Both", dungeon = true },
            ["Halls of Lightning"]   = { mapID = 138, faction = "Both", dungeon = true },
            ["The Oculus"]           = { mapID = 142, faction = "Both", dungeon = true },
            ["Pit of Saron"]         = { mapID = 183, faction = "Both", dungeon = true },
        },
    },

    -----------------------------------------------------------------
    -- PANDARIA
    -----------------------------------------------------------------
    ["Pandaria"] = {
        continent = true,
        mapID = 424,
        children = {
            ["Shrine (Horde)"]       = { mapID = 556, faction = "Horde", capital = true },
            ["Shrine (Alliance)"]    = { mapID = 557, faction = "Alliance", capital = true },
            ["The Jade Forest"]      = { mapID = 371, faction = "Both" },
            ["Valley of the Four Winds"] = { mapID = 376, faction = "Both" },
            ["Krasarang Wilds"]      = { mapID = 418, faction = "Both" },
            ["Kun-Lai Summit"]       = { mapID = 379, faction = "Both" },
            ["Townlong Steppes"]     = { mapID = 388, faction = "Both" },
            ["Dread Wastes"]         = { mapID = 422, faction = "Both" },
            ["Vale of Eternal Blossoms"] = { mapID = 390, faction = "Both" },
            ["Isle of Thunder"]      = { mapID = 504, faction = "Both" },
            ["Timeless Isle"]        = { mapID = 554, faction = "Both" },
        },
    },

    -----------------------------------------------------------------
    -- DRAENOR
    -----------------------------------------------------------------
    ["Draenor"] = {
        continent = true,
        mapID = 572,
        children = {
            ["Frostfire Ridge"]      = { mapID = 525, faction = "Horde" },
            ["Shadowmoon Valley (Draenor)"] = { mapID = 539, faction = "Alliance" },
            ["Gorgrond"]             = { mapID = 543, faction = "Both" },
            ["Talador"]              = { mapID = 535, faction = "Both" },
            ["Spires of Arak"]       = { mapID = 542, faction = "Both" },
            ["Nagrand (Draenor)"]    = { mapID = 550, faction = "Both" },
            ["Tanaan Jungle"]        = { mapID = 534, faction = "Both" },
            ["Ashran"]               = { mapID = 588, faction = "Both" },
        },
    },

    -----------------------------------------------------------------
    -- BROKEN ISLES
    -----------------------------------------------------------------
    ["Broken Isles"] = {
        continent = true,
        mapID = 619,
        children = {
            ["Dalaran (Broken Isles)"] = { mapID = 627, faction = "Both", capital = true },
            ["Azsuna"]               = { mapID = 630, faction = "Both" },
            ["Val'sharah"]           = { mapID = 641, faction = "Both" },
            ["Highmountain"]         = { mapID = 650, faction = "Both" },
            ["Stormheim"]            = { mapID = 634, faction = "Both" },
            ["Suramar"]              = { mapID = 680, faction = "Both" },
            ["Broken Shore"]         = { mapID = 646, faction = "Both" },
            ["Argus"]                = { mapID = 905, faction = "Both" },
        },
    },

    -----------------------------------------------------------------
    -- ZANDALAR / KUL TIRAS
    -----------------------------------------------------------------
    ["Zandalar"] = {
        continent = true,
        mapID = 875,
        children = {
            ["Dazar'alor"]           = { mapID = 1165, faction = "Horde", capital = true },
            ["Zuldazar"]             = { mapID = 862,  faction = "Horde" },
            ["Nazmir"]               = { mapID = 863,  faction = "Horde" },
            ["Vol'dun"]              = { mapID = 864,  faction = "Horde" },
        },
    },

    ["Kul Tiras"] = {
        continent = true,
        mapID = 876,
        children = {
            ["Boralus"]              = { mapID = 1161, faction = "Alliance", capital = true },
            ["Tiragarde Sound"]      = { mapID = 895,  faction = "Alliance" },
            ["Drustvar"]             = { mapID = 896,  faction = "Alliance" },
            ["Stormsong Valley"]     = { mapID = 942,  faction = "Alliance" },
            ["Mechagon"]             = { mapID = 1462, faction = "Both" },
            ["Nazjatar"]             = { mapID = 1355, faction = "Both" },
        },
    },

    -----------------------------------------------------------------
    -- SHADOWLANDS
    -----------------------------------------------------------------
    ["Shadowlands"] = {
        continent = true,
        mapID = 1550,
        children = {
            ["Oribos"]               = { mapID = 1670, faction = "Both", capital = true },
            ["Bastion"]              = { mapID = 1533, faction = "Both" },
            ["Maldraxxus"]           = { mapID = 1536, faction = "Both" },
            ["Ardenweald"]           = { mapID = 1565, faction = "Both" },
            ["Revendreth"]           = { mapID = 1525, faction = "Both" },
            ["The Maw"]              = { mapID = 1543, faction = "Both" },
            ["Korthia"]              = { mapID = 1961, faction = "Both" },
            ["Zereth Mortis"]        = { mapID = 1970, faction = "Both" },
        },
    },

    -----------------------------------------------------------------
    -- DRAGON ISLES
    -----------------------------------------------------------------
    ["Dragon Isles"] = {
        continent = true,
        mapID = 1978,
        children = {
            ["Valdrakken"]           = { mapID = 2112, faction = "Both", capital = true },
            ["The Waking Shores"]    = { mapID = 2022, faction = "Both" },
            ["Ohn'ahran Plains"]     = { mapID = 2023, faction = "Both" },
            ["The Azure Span"]       = { mapID = 2024, faction = "Both" },
            ["Thaldraszus"]          = { mapID = 2025, faction = "Both" },
            ["Zaralek Cavern"]       = { mapID = 2133, faction = "Both" },
            ["Emerald Dream"]        = { mapID = 2200, faction = "Both" },
            ["Forbidden Reach"]      = { mapID = 2151, faction = "Both" },
        },
    },

    -----------------------------------------------------------------
    -- KHAZ ALGAR (THE WAR WITHIN)
    -----------------------------------------------------------------
    ["Khaz Algar"] = {
        continent = true,
        mapID = 2274,
        children = {
            ["Dornogal"]             = { mapID = 2339, faction = "Both", capital = true },
            ["Isle of Dorn"]         = { mapID = 2248, faction = "Both" },
            ["The Ringing Deeps"]    = { mapID = 2214, faction = "Both" },
            ["Hallowfall"]           = { mapID = 2215, faction = "Both" },
            ["Azj-Kahet"]            = { mapID = 2255, faction = "Both" },
        },
    },

    -----------------------------------------------------------------
    -- OUTLAND
    -----------------------------------------------------------------
    ["Outland"] = {
        continent = true,
        mapID = 101,
        children = {
            ["Shattrath City"]       = { mapID = 111, faction = "Both", capital = true },
            ["Hellfire Peninsula"]   = { mapID = 100, faction = "Both" },
            ["Zangarmarsh"]          = { mapID = 102, faction = "Both" },
            ["Terokkar Forest"]      = { mapID = 108, faction = "Both" },
            ["Nagrand"]              = { mapID = 107, faction = "Both" },
            ["Blade's Edge Mountains"] = { mapID = 105, faction = "Both" },
            ["Netherstorm"]          = { mapID = 109, faction = "Both" },
            ["Shadowmoon Valley"]    = { mapID = 104, faction = "Both" },
            -- Dungeons
            ["Hellfire Ramparts"]    = { mapID = 347, faction = "Both", dungeon = true },
            ["The Blood Furnace"]    = { mapID = 348, faction = "Both", dungeon = true },
            ["The Shattered Halls"]  = { mapID = 349, faction = "Both", dungeon = true },
            ["The Slave Pens"]       = { mapID = 265, faction = "Both", dungeon = true },
            ["The Underbog"]         = { mapID = 262, faction = "Both", dungeon = true },
            ["Mana-Tombs"]           = { mapID = 272, faction = "Both", dungeon = true },
            ["Shadow Labyrinth"]     = { mapID = 264, faction = "Both", dungeon = true },
            ["The Mechanar"]         = { mapID = 267, faction = "Both", dungeon = true },
            ["The Arcatraz"]         = { mapID = 269, faction = "Both", dungeon = true },
        },
    },

    -----------------------------------------------------------------
    -- DUNGEONS (Current Expansion - TWW)
    -----------------------------------------------------------------
    ["Dungeons"] = {
        continent = true,
        mapID = 0,
        children = {
            -- The War Within Dungeons
            ["The Rookery"]          = { mapID = 2315, faction = "Both", dungeon = true },
            ["The Stonevault"]       = { mapID = 2341, faction = "Both", dungeon = true },
            ["City of Threads"]      = { mapID = 2343, faction = "Both", dungeon = true },
            ["Ara-Kara"]             = { mapID = 2357, faction = "Both", dungeon = true },
            ["Darkflame Cleft"]      = { mapID = 2359, faction = "Both", dungeon = true },
            ["Priory of the Sacred Flame"] = { mapID = 2361, faction = "Both", dungeon = true },
            ["The Dawnbreaker"]      = { mapID = 2360, faction = "Both", dungeon = true },
            ["Cinderbrew Meadery"]   = { mapID = 2358, faction = "Both", dungeon = true },
        },
    },
}

------------------------------------------------------------------------
-- ZONE LOOKUP FUNCTIONS (stored separately to avoid polluting zone data)
------------------------------------------------------------------------

DXD.ZoneLookup = {}

--- Find a map ID by zone name (case-insensitive)
function DXD.ZoneLookup:FindMapID(name)
    name = strlower(name)
    for continentName, continent in pairs(DXD.ZoneData) do
        if type(continent) == "table" and continent.children then
            for zoneName, zone in pairs(continent.children) do
                if strlower(zoneName) == name then
                    return zone.mapID
                end
            end
        end
    end
    return nil
end
