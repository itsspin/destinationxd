------------------------------------------------------------------------
-- DestinationXD - PortalDatabase.lua
-- Runtime portal/transport database interface
-- Wraps Data/PortalData.lua with lookup and search functions
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local PortalDatabase = {}
DXD:RegisterModule("PortalDatabase", PortalDatabase)

-- Portal data cache
local portalsBySource = {}   -- [mapID] = { portal1, portal2, ... }
local portalsByDest = {}     -- [mapID] = { portal1, portal2, ... }
local allPortals = {}
local playerFaction = nil

------------------------------------------------------------------------
-- DATA LOADING
------------------------------------------------------------------------

function PortalDatabase:LoadData()
    if not DXD.PortalData then
        DXD:Debug("PortalDatabase: No portal data found")
        return
    end

    allPortals = DXD.PortalData
    wipe(portalsBySource)
    wipe(portalsByDest)

    -- Build lookup indices
    for i, portal in ipairs(allPortals) do
        portal.index = i

        -- Index by source map
        local srcMap = portal.srcMapID
        if srcMap then
            if not portalsBySource[srcMap] then
                portalsBySource[srcMap] = {}
            end
            table.insert(portalsBySource[srcMap], portal)
        end

        -- Index by destination map
        local dstMap = portal.dstMapID
        if dstMap then
            if not portalsByDest[dstMap] then
                portalsByDest[dstMap] = {}
            end
            table.insert(portalsByDest[dstMap], portal)
        end
    end

    DXD:Debug("PortalDatabase: Loaded " .. #allPortals .. " portals")
end

------------------------------------------------------------------------
-- FACTION DETECTION
------------------------------------------------------------------------

local function GetPlayerFaction()
    if playerFaction then return playerFaction end
    local _, faction = UnitFactionGroup("player")
    playerFaction = faction
    return faction
end

--- Check if a portal is usable by the current player
local function IsPortalUsable(portal)
    if not portal.faction or portal.faction == "Both" then
        return true
    end
    return portal.faction == GetPlayerFaction()
end

------------------------------------------------------------------------
-- QUERIES
------------------------------------------------------------------------

--- Get all portals departing from a given map
-- @param mapID source map ID
-- @return table of portal entries
function PortalDatabase:GetPortalsFromMap(mapID)
    local portals = portalsBySource[mapID]
    if not portals then return {} end

    local usable = {}
    for _, portal in ipairs(portals) do
        if IsPortalUsable(portal) then
            table.insert(usable, portal)
        end
    end
    return usable
end

--- Get all portals that go TO a given map
-- @param mapID destination map ID
-- @return table of portal entries
function PortalDatabase:GetPortalsToMap(mapID)
    local portals = portalsByDest[mapID]
    if not portals then return {} end

    local usable = {}
    for _, portal in ipairs(portals) do
        if IsPortalUsable(portal) then
            table.insert(usable, portal)
        end
    end
    return usable
end

--- Find the nearest portal to a world position
-- @param worldX, worldY player world position
-- @param mapID current map
-- @return portal, distance (or nil)
function PortalDatabase:FindNearestPortal(worldX, worldY, mapID)
    local portals = self:GetPortalsFromMap(mapID)
    if #portals == 0 then return nil end

    local HBD = DXD.HBD
    local nearest, nearestDist = nil, math.huge

    for _, portal in ipairs(portals) do
        if portal.srcX and portal.srcY then
            local portalWorldX, portalWorldY = HBD:GetWorldCoordinatesFromZone(
                portal.srcX, portal.srcY, portal.srcMapID)
            if portalWorldX and portalWorldY then
                local dist = DXD.Utils.Distance2D(worldX, worldY, portalWorldX, portalWorldY)
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = portal
                end
            end
        end
    end

    return nearest, nearestDist
end

--- Find all portals that connect two maps (directly or via one hop)
-- @param fromMapID source map
-- @param toMapID destination map
-- @return table of route options
function PortalDatabase:FindConnections(fromMapID, toMapID)
    local connections = {}

    -- Direct portals
    local fromPortals = self:GetPortalsFromMap(fromMapID)
    for _, portal in ipairs(fromPortals) do
        if portal.dstMapID == toMapID then
            table.insert(connections, {
                type = "direct",
                steps = { portal },
                cost = portal.travelTime or 5,
            })
        end
    end

    -- One-hop connections (via a hub city)
    local hubMaps = {}
    for _, portal in ipairs(fromPortals) do
        local hubMap = portal.dstMapID
        if hubMap and hubMap ~= fromMapID then
            hubMaps[hubMap] = portal
        end
    end

    for hubMap, firstPortal in pairs(hubMaps) do
        local hubPortals = self:GetPortalsFromMap(hubMap)
        for _, secondPortal in ipairs(hubPortals) do
            if secondPortal.dstMapID == toMapID then
                table.insert(connections, {
                    type = "via_hub",
                    hub = hubMap,
                    steps = { firstPortal, secondPortal },
                    cost = (firstPortal.travelTime or 5) + (secondPortal.travelTime or 5),
                })
            end
        end
    end

    -- Sort by cost
    table.sort(connections, function(a, b) return a.cost < b.cost end)

    return connections
end

--- Get total portal count
function PortalDatabase:GetCount()
    return #allPortals
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function PortalDatabase:Initialize()
    self:LoadData()
    DXD:Debug("PortalDatabase initialized")
end
