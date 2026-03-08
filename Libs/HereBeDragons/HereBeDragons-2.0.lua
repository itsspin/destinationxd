-- HereBeDragons-2.0 - Coordinate translation library for WoW
-- Provides world coordinate translation, distance calculations, and map utilities

local MAJOR, MINOR = "HereBeDragons-2.0", 12
local HereBeDragons, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not HereBeDragons then return end

local CBH = LibStub("CallbackHandler-1.0")

HereBeDragons.callbacks = HereBeDragons.callbacks or CBH:New(HereBeDragons)

local PI2 = math.pi * 2
local atan2 = math.atan2
local sqrt = math.sqrt
local cos = math.cos
local sin = math.sin

-- Map data storage
local mapData = {}
local worldMapData = {}
local transforms = {}
local instanceIDOverrides = {}

-- Internal: Get map data from WoW API
local function GetMapDataFromAPI(uiMapID)
    if mapData[uiMapID] then return mapData[uiMapID] end

    local info = C_Map.GetMapInfo(uiMapID)
    if not info then return nil end

    -- Get world coordinates for this map
    local topLeft = CreateVector2D(0, 0)
    local bottomRight = CreateVector2D(1, 1)

    local success1, tl = pcall(C_Map.GetWorldPosFromMapPos, uiMapID, topLeft)
    local success2, br = pcall(C_Map.GetWorldPosFromMapPos, uiMapID, bottomRight)

    if success1 and success2 and tl and br then
        local instanceID = tl.instanceID or 0
        local tlX, tlY = tl.position:GetXY()
        local brX, brY = br.position:GetXY()
        local width = brX - tlX
        local height = brY - tlY

        mapData[uiMapID] = {
            instance = instanceID,
            name = info.name,
            mapType = info.mapType,
            parent = info.parentMapID,
            left = tlX,
            top = tlY,
            width = width,
            height = height,
        }
    else
        mapData[uiMapID] = {
            instance = 0,
            name = info.name or "Unknown",
            mapType = info.mapType or 0,
            parent = info.parentMapID or 0,
        }
    end

    return mapData[uiMapID]
end

--- Get the player's current position in world coordinates
-- @return x, y, instance
function HereBeDragons:GetPlayerWorldPosition()
    -- UnitPosition returns (posY, posX, posZ, instanceID) - note swapped X/Y!
    local posY, posX, posZ, instanceID = UnitPosition("player")
    if not posX or not posY then return nil, nil, nil end
    return posX, posY, instanceID
end

--- Get the player's current zone map
-- @return uiMapID
function HereBeDragons:GetPlayerZone()
    return C_Map.GetBestMapForUnit("player")
end

--- Get player position on the current map (0-1 coordinates)
-- @return x, y, mapID
function HereBeDragons:GetPlayerZonePosition(allowOutOfBounds)
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nil, nil, nil end

    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return nil, nil, mapID end

    local x, y = pos:GetXY()
    if not allowOutOfBounds and (x <= 0 and y <= 0) then
        return nil, nil, mapID
    end
    return x, y, mapID
end

--- Convert map coordinates to world coordinates
-- @param x map x (0-1)
-- @param y map y (0-1)
-- @param uiMapID the map ID
-- @return worldX, worldY, instance
function HereBeDragons:GetWorldCoordinatesFromZone(x, y, uiMapID)
    if not uiMapID or not x or not y then return nil, nil, nil end

    local mapPos = CreateVector2D(x, y)
    local success, worldPos = pcall(C_Map.GetWorldPosFromMapPos, uiMapID, mapPos)
    if not success or not worldPos then return nil, nil, nil end

    local wx, wy = worldPos.position:GetXY()
    return wx, wy, worldPos.instanceID
end

--- Convert world coordinates to map coordinates
-- @param worldX world x
-- @param worldY world y
-- @param uiMapID target map ID
-- @return mapX, mapY (0-1)
function HereBeDragons:GetZoneCoordinatesFromWorld(worldX, worldY, uiMapID)
    if not uiMapID or not worldX or not worldY then return nil, nil end
    local data = GetMapDataFromAPI(uiMapID)
    if not data or not data.width or data.width == 0 then return nil, nil end

    local mapX = (worldX - data.left) / data.width
    local mapY = (worldY - data.top) / data.height
    return mapX, mapY
end

--- Calculate the distance between two world points
-- @return distance in yards
function HereBeDragons:GetWorldDistance(instanceA, xA, yA, instanceB, xB, yB)
    if not instanceA or not instanceB or instanceA ~= instanceB then return nil end
    if not xA or not yA or not xB or not yB then return nil end
    local dx = xB - xA
    local dy = yB - yA
    return sqrt(dx * dx + dy * dy)
end

--- Calculate the angle between two world points (in radians)
-- @return angle in radians
function HereBeDragons:GetWorldVector(instanceA, xA, yA, instanceB, xB, yB)
    if not instanceA or not instanceB or instanceA ~= instanceB then return nil, nil end
    if not xA or not yA or not xB or not yB then return nil, nil end
    local dx = xB - xA
    local dy = yB - yA
    local distance = sqrt(dx * dx + dy * dy)
    local angle = atan2(-dx, dy)
    if angle < 0 then angle = angle + PI2 end
    return angle, distance
end

--- Get map info
-- @param uiMapID
-- @return table with map data
function HereBeDragons:GetMapInfo(uiMapID)
    return GetMapDataFromAPI(uiMapID)
end
