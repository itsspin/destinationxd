------------------------------------------------------------------------
-- DestinationXD - FloorDetection.lua
-- Multi-floor area detection with Z-range boundaries
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local FloorDetection = {}
DXD:RegisterModule("FloorDetection", FloorDetection)

-- Floor data loaded from Data/FloorData.lua
local floorDB = {}

------------------------------------------------------------------------
-- FLOOR DATABASE
------------------------------------------------------------------------

--- Load floor data from the data module
function FloorDetection:LoadFloorData()
    if DXD.FloorData then
        floorDB = DXD.FloorData
        DXD:Debug("FloorDetection: Loaded " .. self:CountFloors() .. " floor entries")
    end
end

--- Count total floor entries
function FloorDetection:CountFloors()
    local count = 0
    for mapID, floors in pairs(floorDB) do
        count = count + #floors
    end
    return count
end

------------------------------------------------------------------------
-- FLOOR LOOKUP
------------------------------------------------------------------------

--- Determine which floor a Z coordinate belongs to for a given map
-- @param mapID the map ID to look up
-- @param z the Z coordinate (elevation)
-- @return floorIndex, floorName, floorZMin, floorZMax (or nil)
function FloorDetection:GetFloor(mapID, z)
    if not mapID or not z then return nil end

    local floors = floorDB[mapID]
    if not floors then return nil end

    for i, floor in ipairs(floors) do
        if z >= floor.zMin and z <= floor.zMax then
            return i, floor.name, floor.zMin, floor.zMax
        end
    end

    -- Z is outside all known ranges - find closest
    local closestIdx, closestDist = nil, math.huge
    for i, floor in ipairs(floors) do
        local mid = (floor.zMin + floor.zMax) / 2
        local dist = math.abs(z - mid)
        if dist < closestDist then
            closestDist = dist
            closestIdx = i
        end
    end

    if closestIdx then
        local f = floors[closestIdx]
        return closestIdx, f.name, f.zMin, f.zMax
    end

    return nil
end

--- Check if two Z coordinates are on different floors
-- @param mapID the map
-- @param z1 first Z
-- @param z2 second Z
-- @return differentFloor (bool), floor1Name, floor2Name
function FloorDetection:AreDifferentFloors(mapID, z1, z2)
    if not mapID or not z1 or not z2 then return false end

    local floors = floorDB[mapID]
    if not floors then return false end

    local idx1 = self:GetFloor(mapID, z1)
    local idx2 = self:GetFloor(mapID, z2)

    if idx1 and idx2 and idx1 ~= idx2 then
        return true, floors[idx1].name, floors[idx2].name
    end

    return false
end

--- Check if a given mapID has floor data
function FloorDetection:HasFloorData(mapID)
    return floorDB[mapID] ~= nil
end

--- Get all floors for a map
function FloorDetection:GetFloors(mapID)
    return floorDB[mapID]
end

--- Estimate Z for a target on a specific floor
-- @param mapID the map
-- @param floorIndex which floor
-- @return estimated Z (midpoint of floor range)
function FloorDetection:EstimateFloorZ(mapID, floorIndex)
    if not mapID then return nil end
    local floors = floorDB[mapID]
    if not floors or not floors[floorIndex] then return nil end
    local floor = floors[floorIndex]
    return (floor.zMin + floor.zMax) / 2
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function FloorDetection:Initialize()
    self:LoadFloorData()
    DXD:Debug("FloorDetection initialized")
end
