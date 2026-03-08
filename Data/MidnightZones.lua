------------------------------------------------------------------------
-- DestinationXD - MidnightZones.lua
-- Midnight-specific zone data (Quel'Thalas expansion content)
-- Updated as Midnight zone details become available
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

-- Midnight expansion zone details
-- These will be updated with actual map IDs when Midnight launches
DXD.MidnightZones = {
    -----------------------------------------------------------------
    -- ZONE METADATA
    -----------------------------------------------------------------
    zones = {
        {
            name = "Silvermoon City (Renewed)",
            mapID = 2602,
            parentMapID = 2601,
            type = "city",
            faction = "Both",
            hasFlightMaster = true,
            hasPortals = true,
            hasInn = true,
            description = "The restored Blood Elf capital, rebuilt and open to all.",
            landmarks = {
                { name = "Sunfury Spire",      x = 0.54, y = 0.21 },
                { name = "The Royal Exchange",  x = 0.53, y = 0.55 },
                { name = "Murder Row",          x = 0.53, y = 0.72 },
                { name = "Court of the Sun",    x = 0.60, y = 0.34 },
                { name = "Portal Room",         x = 0.50, y = 0.35 },
                { name = "Flight Master",       x = 0.54, y = 0.50 },
            },
        },
        {
            name = "Eversong Woods (Renewed)",
            mapID = 2603,
            parentMapID = 2601,
            type = "zone",
            faction = "Both",
            hasFlightMaster = true,
            levelRange = "68-70",
            description = "The golden forests of the Blood Elves, now accessible to all.",
            landmarks = {
                { name = "Sunstrider Isle",     x = 0.38, y = 0.18 },
                { name = "Falconwing Square",   x = 0.48, y = 0.47 },
                { name = "Fairbreeze Village",  x = 0.44, y = 0.71 },
                { name = "Sunsail Anchorage",   x = 0.31, y = 0.71 },
            },
        },
        {
            name = "Ghostlands (Renewed)",
            mapID = 2604,
            parentMapID = 2601,
            type = "zone",
            faction = "Both",
            hasFlightMaster = true,
            levelRange = "70-72",
            description = "The haunted lands south of Silvermoon, still bearing scars of the Scourge.",
            landmarks = {
                { name = "Tranquillien",        x = 0.46, y = 0.28 },
                { name = "Windrunner Spire",    x = 0.18, y = 0.44 },
                { name = "Deatholme",           x = 0.35, y = 0.85 },
                { name = "Zul'Aman",            x = 0.76, y = 0.64 },
            },
        },
        {
            name = "The Sunwell Plateau",
            mapID = 2605,
            parentMapID = 2601,
            type = "zone",
            faction = "Both",
            hasFlightMaster = true,
            levelRange = "72-80",
            description = "The sacred font of Blood Elf power on the Isle of Quel'Danas.",
            landmarks = {
                { name = "Sun's Reach Harbor",  x = 0.50, y = 0.92 },
                { name = "Sun's Reach Sanctum", x = 0.47, y = 0.40 },
                { name = "The Sunwell",         x = 0.44, y = 0.23 },
            },
        },
        {
            name = "Isle of Quel'Danas",
            mapID = 2606,
            parentMapID = 2601,
            type = "zone",
            faction = "Both",
            hasFlightMaster = true,
            levelRange = "72-80",
            description = "The isle housing the Sunwell, now a major staging area.",
        },
        {
            name = "The Thalassian Pass",
            mapID = 2607,
            parentMapID = 2601,
            type = "zone",
            faction = "Both",
            hasFlightMaster = true,
            levelRange = "70-72",
            description = "The mountain pass connecting Quel'Thalas to the Eastern Plaguelands.",
        },
        {
            name = "Sunstrider Isle",
            mapID = 2608,
            parentMapID = 2601,
            type = "starting_zone",
            faction = "Both",
            levelRange = "1-10",
            description = "The Blood Elf starting area on a floating isle.",
        },
        {
            name = "The Dead Scar",
            mapID = 2609,
            parentMapID = 2601,
            type = "zone",
            faction = "Both",
            levelRange = "70-80",
            description = "The path of destruction left by Arthas's march to the Sunwell.",
        },
    },

    -----------------------------------------------------------------
    -- MIDNIGHT-SPECIFIC PORTALS
    -----------------------------------------------------------------
    portals = {
        -- From Midnight hub to old world
        { from = "Silvermoon (Midnight)", fromMapID = 2602, to = "Orgrimmar",   toMapID = 85 },
        { from = "Silvermoon (Midnight)", fromMapID = 2602, to = "Stormwind",   toMapID = 84 },
        { from = "Silvermoon (Midnight)", fromMapID = 2602, to = "Dornogal",    toMapID = 2339 },
        { from = "Silvermoon (Midnight)", fromMapID = 2602, to = "Valdrakken",  toMapID = 2112 },
        { from = "Silvermoon (Midnight)", fromMapID = 2602, to = "Dalaran",     toMapID = 627 },
    },

    -----------------------------------------------------------------
    -- MIDNIGHT FLIGHT PATHS (placeholder)
    -----------------------------------------------------------------
    flightPaths = {
        { name = "Silvermoon City",      mapID = 2602, x = 0.54, y = 0.50 },
        { name = "Falconwing Square",    mapID = 2603, x = 0.48, y = 0.47 },
        { name = "Fairbreeze Village",   mapID = 2603, x = 0.44, y = 0.71 },
        { name = "Tranquillien",         mapID = 2604, x = 0.46, y = 0.28 },
        { name = "Sun's Reach Harbor",   mapID = 2605, x = 0.50, y = 0.92 },
        { name = "Thalassian Pass",      mapID = 2607, x = 0.50, y = 0.50 },
    },
}

------------------------------------------------------------------------
-- HELPER: Get Midnight zone info by map ID
------------------------------------------------------------------------

function DXD.MidnightZones:GetZoneInfo(mapID)
    for _, zone in ipairs(self.zones) do
        if zone.mapID == mapID then
            return zone
        end
    end
    return nil
end

--- Check if a map ID is a Midnight zone
function DXD.MidnightZones:IsMidnightZone(mapID)
    return self:GetZoneInfo(mapID) ~= nil
end

--- Get all landmarks for a Midnight zone
function DXD.MidnightZones:GetLandmarks(mapID)
    local zone = self:GetZoneInfo(mapID)
    return zone and zone.landmarks or {}
end
