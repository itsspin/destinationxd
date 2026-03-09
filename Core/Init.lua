------------------------------------------------------------------------
-- DestinationXD - Init.lua
-- Addon initialization, saved variables, event bootstrap
-- "You'll actually get there."
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

-- Global namespace
DestinationXD = DXD
DXD.name = ADDON_NAME
DXD.version = "1.0.0"
DXD.author = "Spacebutt"
DXD.tagline = "You'll actually get there."

-- Module registry
DXD.modules = {}

-- Libraries
DXD.HBD = LibStub("HereBeDragons-2.0")
DXD.HBDPins = LibStub("HereBeDragons-Pins-2.0")
DXD.LDB = LibStub("LibDataBroker-1.1")
DXD.LDBIcon = LibStub("LibDBIcon-1.0")

-- Runtime state
DXD.state = {
    -- Player state
    playerX = 0,
    playerY = 0,
    playerZ = 0,
    playerMapID = 0,
    playerFacing = 0,
    playerInstanceID = 0,
    playerMoving = false,
    lastMoveTime = 0,

    -- Active navigation target
    hasTarget = false,
    targetType = "none",       -- "quest", "waypoint", "corpse", "travel", "tomtom"
    targetMapID = nil,
    targetMapX = nil,
    targetMapY = nil,
    targetWorldX = nil,
    targetWorldY = nil,
    targetWorldZ = nil,
    targetName = nil,
    targetDescription = nil,

    -- Computed navigation data
    distance2D = 0,
    distance3D = 0,
    distanceHorizontal = 0,
    distanceVertical = 0,
    elevationDelta = 0,
    elevationState = "level",  -- "above", "below", "level"
    bearing = 0,
    isObstructed = false,

    -- Travel planner
    travelRoute = nil,
    travelRouteStep = 0,

    -- System
    initialized = false,
    debugMode = false,
}

------------------------------------------------------------------------
-- MODULE REGISTRATION
------------------------------------------------------------------------

--- Register a module with the addon
function DXD:RegisterModule(name, module)
    self.modules[name] = module
    return module
end

--- Get a registered module
function DXD:GetModule(name)
    return self.modules[name]
end

------------------------------------------------------------------------
-- PRINTING
------------------------------------------------------------------------

local CHAT_PREFIX = "|cff66d9ef[DXD]|r "

function DXD:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(CHAT_PREFIX .. tostring(msg))
end

function DXD:Debug(msg)
    if self.state.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage(CHAT_PREFIX .. "|cff888888" .. tostring(msg) .. "|r")
    end
end

------------------------------------------------------------------------
-- EVENT FRAMEWORK
------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame", "DestinationXDEventFrame", UIParent)
local eventHandlers = {}

function DXD:RegisterEvent(event, handler)
    eventHandlers[event] = handler
    eventFrame:RegisterEvent(event)
end

function DXD:UnregisterEvent(event)
    eventHandlers[event] = nil
    eventFrame:UnregisterEvent(event)
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    local handler = eventHandlers[event]
    if handler then
        handler(DXD, event, ...)
    end
end)

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

local function InitializeSavedVariables()
    if not DestinationXDDB then
        DestinationXDDB = {}
    end
    -- Merge defaults into saved variables (preserving user settings)
    DXD.Utils.MergeDefaults(DestinationXDDB, DXD.Config.DEFAULTS)
    DXD.db = DestinationXDDB
end

local function InitializeModules()
    -- Initialize all registered modules in order
    local initOrder = {
        "BeaconAnimations", "Beacon", "ElevationTracker", "FloorDetection",
        "ProximityManager",
        "QuestTracker", "WaypointTracker", "IntegrationBridge",
        "TravelPlanner", "PortalDatabase", "FlightPathGraph",
        "RouteDisplay", "Pinpoint", "MinimapButton", "SettingsPanel",
        "TravelPlannerFrame", "RadialMenu",
    }

    for _, name in ipairs(initOrder) do
        local mod = DXD.modules[name]
        if mod and mod.Initialize then
            local success, err = pcall(mod.Initialize, mod)
            if not success then
                DXD:Print("|cffff4444Error initializing " .. name .. ": " .. tostring(err) .. "|r")
            else
                DXD:Debug("Module initialized: " .. name)
            end
        end
    end
end

------------------------------------------------------------------------
-- MAIN UPDATE LOOP
------------------------------------------------------------------------

local posAccum = DXD.Utils.CreateAccumulator(DXD.Config.UPDATE_RATES.POSITION)
local speedAccum = DXD.Utils.CreateAccumulator(DXD.Config.UPDATE_RATES.SPEED)

local function UpdatePlayerPosition()
    -- UnitPosition returns (posY, posX, posZ, instanceID)
    -- NOTE: posZ is always 0 in retail WoW (placeholder value).
    -- We use C_Navigation.GetDistance() + 2D distance triangulation
    -- for elevation estimation instead (see ElevationTracker.lua).
    local posY, posX, posZ, instanceID = UnitPosition("player")
    if posX and posY then
        -- Detect movement
        local moved = (posX ~= DXD.state.playerX or posY ~= DXD.state.playerY)
        if moved then
            DXD.state.playerMoving = true
            DXD.state.lastMoveTime = GetTime()
        elseif GetTime() - DXD.state.lastMoveTime > 0.5 then
            DXD.state.playerMoving = false
        end

        DXD.state.playerX = posX
        DXD.state.playerY = posY
        -- posZ is always 0, so we don't rely on it for elevation
        DXD.state.playerZ = posZ or 0
        DXD.state.playerInstanceID = instanceID or 0
    end

    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID then
        DXD.state.playerMapID = mapID
    end

    local facing = GetPlayerFacing()
    if facing then
        DXD.state.playerFacing = facing
    end
end

local function OnUpdate(self, elapsed)
    if not DXD.state.initialized then return end
    if not DXD.db.enabled then return end

    -- Update player position every frame for smooth visuals
    UpdatePlayerPosition()

    -- Update speed at 5fps
    if speedAccum:ShouldUpdate(elapsed) then
        DXD.Utils.UpdateSpeed()
    end

    -- Let modules handle their own update rates
    for name, mod in pairs(DXD.modules) do
        if mod.OnUpdate then
            mod:OnUpdate(elapsed)
        end
    end
end

eventFrame:SetScript("OnUpdate", OnUpdate)

------------------------------------------------------------------------
-- EVENT HANDLERS
------------------------------------------------------------------------

DXD:RegisterEvent("ADDON_LOADED", function(self, event, addon)
    if addon ~= ADDON_NAME then return end
    InitializeSavedVariables()
    DXD:Debug("SavedVariables loaded")
    DXD:UnregisterEvent("ADDON_LOADED")
end)

DXD:RegisterEvent("PLAYER_LOGIN", function(self, event)
    InitializeModules()
    DXD:Debug("Modules initialized")
end)

DXD:RegisterEvent("PLAYER_ENTERING_WORLD", function(self, event, isInitialLogin, isReloadingUi)
    -- Start the main loop
    UpdatePlayerPosition()
    DXD.state.initialized = true

    if isInitialLogin then
        DXD:Print(DXD.tagline .. " |cff888888v" .. DXD.version .. "|r")
    end

    DXD:Debug("Entering world, position tracking active")
end)

-- Navigation events
DXD:RegisterEvent("SUPER_TRACKING_CHANGED", function(self, event)
    -- Notify tracker modules
    local tracker = DXD:GetModule("QuestTracker")
    if tracker and tracker.OnSuperTrackingChanged then
        tracker:OnSuperTrackingChanged()
    end
    local wpTracker = DXD:GetModule("WaypointTracker")
    if wpTracker and wpTracker.OnSuperTrackingChanged then
        wpTracker:OnSuperTrackingChanged()
    end
end)

DXD:RegisterEvent("USER_WAYPOINT_UPDATED", function(self, event)
    local wpTracker = DXD:GetModule("WaypointTracker")
    if wpTracker and wpTracker.OnWaypointUpdated then
        wpTracker:OnWaypointUpdated()
    end
end)

DXD:RegisterEvent("PLAYER_DEAD", function(self, event)
    local tracker = DXD:GetModule("QuestTracker")
    if tracker and tracker.OnPlayerDead then
        tracker:OnPlayerDead()
    end
end)

DXD:RegisterEvent("PLAYER_ALIVE", function(self, event)
    local tracker = DXD:GetModule("QuestTracker")
    if tracker and tracker.OnPlayerAlive then
        tracker:OnPlayerAlive()
    end
end)

DXD:RegisterEvent("ZONE_CHANGED_NEW_AREA", function(self, event)
    UpdatePlayerPosition()
    -- Notify travel planner
    local planner = DXD:GetModule("TravelPlanner")
    if planner and planner.OnZoneChanged then
        planner:OnZoneChanged()
    end
end)

DXD:RegisterEvent("ZONE_CHANGED", function(self, event)
    UpdatePlayerPosition()
end)

DXD:RegisterEvent("ZONE_CHANGED_INDOORS", function(self, event)
    UpdatePlayerPosition()
end)

------------------------------------------------------------------------
-- PUBLIC API
------------------------------------------------------------------------

--- Set a navigation target from map coordinates
-- Sets both internal state AND a native WoW waypoint (for WaypointUI etc.)
-- @param mapID the zone/map ID
-- @param mapX normalized X (0-1)
-- @param mapY normalized Y (0-1)
-- @param targetType "quest", "waypoint", "corpse", "travel", "tomtom", "dungeon", "flight"
-- @param name display name
-- @param description optional subtitle
function DXD:SetTarget(mapID, mapX, mapY, targetType, name, description)
    local state = self.state

    -- Guard against re-entrant calls from USER_WAYPOINT_UPDATED.
    -- The boolean blocks synchronous re-entry; the timer blocks DEFERRED
    -- event re-entry (USER_WAYPOINT_UPDATED fires asynchronously after
    -- C_Map.SetUserWaypoint returns).
    if self._settingTarget then return end
    if self._settingTargetUntil and GetTime() < self._settingTargetUntil then return end
    self._settingTarget = true

    -- Clear any existing user waypoint first
    pcall(function()
        if C_Map and C_Map.ClearUserWaypoint then
            C_Map.ClearUserWaypoint()
        end
    end)

    state.targetType = targetType or "waypoint"
    state.targetName = name
    state.targetDescription = description

    -- Normalize coordinates (some callers pass 0-100, we need 0-1)
    local wpX, wpY = mapX, mapY
    if wpX and wpX > 1 then wpX = wpX / 100 end
    if wpY and wpY > 1 then wpY = wpY / 100 end

    -- ----------------------------------------------------------------
    -- WORLD COORDINATE RESOLUTION (for arrow / distance calculations)
    -- Try the original map first, then walk parents, then player map.
    -- This does NOT affect where the WoW waypoint pin is placed.
    -- ----------------------------------------------------------------
    local worldX, worldY = self.HBD:GetWorldCoordinatesFromZone(wpX, wpY, mapID)

    if not worldX or not worldY then
        -- Walk parent chain for world-coord resolution only
        local resolvedMap = mapID
        for attempt = 1, 5 do
            local mapInfo = resolvedMap and C_Map.GetMapInfo(resolvedMap)
            if mapInfo and mapInfo.parentMapID and mapInfo.parentMapID > 0 then
                resolvedMap = mapInfo.parentMapID
                worldX, worldY = self.HBD:GetWorldCoordinatesFromZone(0.5, 0.5, resolvedMap)
                if worldX and worldY then
                    self:Debug("World coords resolved via parent " .. resolvedMap)
                    break
                end
            else
                break
            end
        end
    end

    if not worldX or not worldY then
        local playerMap = state.playerMapID
        if playerMap and playerMap > 0 then
            worldX, worldY = self.HBD:GetWorldCoordinatesFromZone(0.5, 0.5, playerMap)
        end
    end

    -- Store the ORIGINAL map and coordinates (not the fallback parent)
    state.targetMapID = mapID
    state.targetMapX = wpX
    state.targetMapY = wpY

    if worldX and worldY then
        state.targetWorldX = worldX
        state.targetWorldY = worldY
        state.hasTarget = true
    else
        self:Debug("Failed to convert target to world coordinates")
        state.hasTarget = false
    end

    -- ----------------------------------------------------------------
    -- WOW WAYPOINT PIN — use the ORIGINAL mapID + coords first.
    -- Only fall back to a parent map if the original is unwaypointable.
    -- ----------------------------------------------------------------
    local wpSet = false
    pcall(function()
        if C_Map and C_Map.SetUserWaypoint then
            local point = UiMapPoint.CreateFromCoordinates(mapID, wpX, wpY)
            C_Map.SetUserWaypoint(point)
            wpSet = C_Map.HasUserWaypoint()
        end
    end)

    -- If the original map isn't waypointable, walk parents for pin only
    if not wpSet then
        local resolvedMap = mapID
        for attempt = 1, 5 do
            local mapInfo = resolvedMap and C_Map.GetMapInfo(resolvedMap)
            if mapInfo and mapInfo.parentMapID and mapInfo.parentMapID > 0 then
                resolvedMap = mapInfo.parentMapID
                local ok = pcall(function()
                    local point = UiMapPoint.CreateFromCoordinates(resolvedMap, wpX, wpY)
                    C_Map.SetUserWaypoint(point)
                end)
                if ok then
                    wpSet = pcall(function() return C_Map.HasUserWaypoint() end)
                    if wpSet then break end
                end
            else
                break
            end
        end
    end

    pcall(function()
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
    end)

    -- Print destination info (once)
    local displayName = name or "Waypoint"
    if description then
        displayName = displayName .. " |cff888888(" .. description .. ")|r"
    end
    self:Print("Navigating to: " .. displayName)

    -- Notify all modules
    for _, mod in pairs(self.modules) do
        if mod.OnTargetChanged then
            mod:OnTargetChanged()
        end
    end

    self._settingTarget = false
    -- Block deferred event re-entry for 0.5 seconds
    self._settingTargetUntil = GetTime() + 0.5
end

--- Set a target with explicit world coordinates (including Z)
function DXD:SetTargetWorld(worldX, worldY, worldZ, targetType, name, description)
    local state = self.state

    state.targetWorldX = worldX
    state.targetWorldY = worldY
    state.targetWorldZ = worldZ
    state.targetType = targetType or "waypoint"
    state.targetName = name
    state.targetDescription = description
    state.hasTarget = true

    -- Try to reverse-map to map coordinates
    local mapID = self.state.playerMapID
    if mapID then
        local mapX, mapY = self.HBD:GetZoneCoordinatesFromWorld(worldX, worldY, mapID)
        state.targetMapID = mapID
        state.targetMapX = mapX
        state.targetMapY = mapY
    end

    for _, mod in pairs(self.modules) do
        if mod.OnTargetChanged then
            mod:OnTargetChanged()
        end
    end
end

--- Clear the current navigation target
function DXD:ClearTarget()
    local state = self.state

    state.hasTarget = false
    state.targetType = "none"
    state.targetMapID = nil
    state.targetMapX = nil
    state.targetMapY = nil
    state.targetWorldX = nil
    state.targetWorldY = nil
    state.targetWorldZ = nil
    state.targetName = nil
    state.targetDescription = nil
    state.distance2D = 0
    state.distance3D = 0
    state.distanceHorizontal = 0
    state.distanceVertical = 0
    state.elevationDelta = 0
    state.elevationState = "level"
    state.isObstructed = false

    -- Clear native WoW waypoint
    pcall(function()
        if C_Map and C_Map.ClearUserWaypoint then
            C_Map.ClearUserWaypoint()
        end
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(false)
        end
    end)

    for _, mod in pairs(self.modules) do
        if mod.OnTargetCleared then
            mod:OnTargetCleared()
        end
    end
end

--- Get the current beacon color based on target type
function DXD:GetBeaconColor()
    local colors = self.Config.COLORS
    local targetType = self.state.targetType

    if targetType == "quest" then
        return colors.BEACON_QUEST
    elseif targetType == "waypoint" then
        return colors.BEACON_WAYPOINT
    elseif targetType == "corpse" then
        return colors.BEACON_CORPSE
    elseif targetType == "travel" then
        return colors.BEACON_TRAVEL
    elseif targetType == "tomtom" then
        return colors.BEACON_TOMTOM
    elseif targetType == "dungeon" then
        return colors.BEACON_DUNGEON
    elseif targetType == "flight" then
        return colors.BEACON_FLIGHT
    else
        return colors.BEACON_WAYPOINT
    end
end
