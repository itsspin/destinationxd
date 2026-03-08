------------------------------------------------------------------------
-- DestinationXD - FlightPathGraph.lua
-- Flight path network graph for route planning
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local FlightPathGraph = {}
DXD:RegisterModule("FlightPathGraph", FlightPathGraph)

local Utils = DXD.Utils

-- Flight node cache
local knownNodes = {}       -- [nodeID] = { name, mapID, x, y, faction, connected = {} }
local nodesByMap = {}        -- [mapID] = { nodeID1, nodeID2, ... }
local graphBuilt = false

------------------------------------------------------------------------
-- FLIGHT DATA COLLECTION
------------------------------------------------------------------------

--- Scan taxi nodes for the current map
-- Must be called while at a flight master
function FlightPathGraph:ScanCurrentMap()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end

    local nodes = C_TaxiMap.GetAllTaxiNodes(mapID)
    if not nodes then return end

    for _, node in ipairs(nodes) do
        if node.nodeID then
            knownNodes[node.nodeID] = {
                nodeID = node.nodeID,
                name = node.name,
                mapID = mapID,
                x = node.position and node.position.x or 0,
                y = node.position and node.position.y or 0,
                faction = node.faction or "Both",
                state = node.state,  -- reachable, unreachable, current
            }

            if not nodesByMap[mapID] then
                nodesByMap[mapID] = {}
            end
            nodesByMap[mapID][node.nodeID] = true
        end
    end

    DXD:Debug("FlightPathGraph: Scanned " .. #nodes .. " nodes on map " .. mapID)
end

--- Get all known flight nodes on a map
function FlightPathGraph:GetNodesOnMap(mapID)
    if not nodesByMap[mapID] then return {} end
    local nodes = {}
    for nodeID in pairs(nodesByMap[mapID]) do
        if knownNodes[nodeID] then
            table.insert(nodes, knownNodes[nodeID])
        end
    end
    return nodes
end

--- Find the nearest flight node to a position
-- @param mapID map to search
-- @param mapX, mapY position (0-1)
-- @return node, distance
function FlightPathGraph:FindNearestNode(mapID, mapX, mapY)
    local nodes = self:GetNodesOnMap(mapID)
    if #nodes == 0 then return nil end

    local nearest, nearestDist = nil, math.huge
    for _, node in ipairs(nodes) do
        local dist = Utils.Distance2D(mapX, mapY, node.x, node.y)
        if dist < nearestDist then
            nearestDist = dist
            nearest = node
        end
    end

    return nearest, nearestDist
end

--- Estimate flight time between two nodes
-- This is approximate since we don't have actual flight times
-- @param fromNode source flight node
-- @param toNode destination flight node
-- @return estimated seconds
function FlightPathGraph:EstimateFlightTime(fromNode, toNode)
    if not fromNode or not toNode then return nil end

    -- Calculate map distance and convert to approximate yards
    local HBD = DXD.HBD
    local fromWorldX, fromWorldY = HBD:GetWorldCoordinatesFromZone(
        fromNode.x, fromNode.y, fromNode.mapID)
    local toWorldX, toWorldY = HBD:GetWorldCoordinatesFromZone(
        toNode.x, toNode.y, toNode.mapID)

    if fromWorldX and fromWorldY and toWorldX and toWorldY then
        local dist = Utils.Distance2D(fromWorldX, fromWorldY, toWorldX, toWorldY)
        -- Flight path speed is roughly 30 yards/sec with winding paths (~1.5x direct)
        return (dist * 1.5) / 30
    end

    -- Fallback: assume 60 seconds for unknown routes
    return 60
end

--- Get known node count
function FlightPathGraph:GetNodeCount()
    local count = 0
    for _ in pairs(knownNodes) do count = count + 1 end
    return count
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function FlightPathGraph:Initialize()
    -- Register for taxi events to build our graph
    DXD:RegisterEvent("TAXIMAP_OPENED", function()
        FlightPathGraph:ScanCurrentMap()
    end)

    DXD:Debug("FlightPathGraph initialized")
end
