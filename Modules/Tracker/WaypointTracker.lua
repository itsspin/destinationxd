------------------------------------------------------------------------
-- DestinationXD - WaypointTracker.lua
-- User waypoint (/way) and map pin tracking
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local WaypointTracker = {}
DXD:RegisterModule("WaypointTracker", WaypointTracker)

local Utils = DXD.Utils

------------------------------------------------------------------------
-- WAYPOINT EVENTS
------------------------------------------------------------------------

--- Called when the user creates or modifies a map waypoint
function WaypointTracker:OnWaypointUpdated()
    if not DXD.state.initialized then return end

    -- If SetTarget is currently running, this event was triggered by US
    -- setting the waypoint programmatically. Do NOT re-process it.
    if DXD._settingTarget then return end

    local hasWaypoint = C_Map.HasUserWaypoint()
    if not hasWaypoint then
        -- Waypoint was cleared
        if DXD.state.targetType == "waypoint" then
            DXD:ClearTarget()
        end
        return
    end

    -- Get the waypoint info
    local waypoint = C_Map.GetUserWaypoint()
    if not waypoint then return end

    local mapID = waypoint.uiMapID
    local x = waypoint.position.x
    local y = waypoint.position.y

    if not mapID or not x or not y then return end

    -- Get map info for display
    local mapInfo = C_Map.GetMapInfo(mapID)
    local zoneName = mapInfo and mapInfo.name or "Unknown"
    local displayX = math.floor(x * 1000 + 0.5) / 10
    local displayY = math.floor(y * 1000 + 0.5) / 10

    local name = zoneName .. " (" .. displayX .. ", " .. displayY .. ")"

    DXD:SetTarget(mapID, x, y, "waypoint", name)

    DXD:Debug("Tracking user waypoint: " .. name)
end

--- Called when super tracking changes
function WaypointTracker:OnSuperTrackingChanged()
    if not DXD.state.initialized then return end
    if DXD._settingTarget then return end

    if C_SuperTrack.IsSuperTrackingUserWaypoint() then
        self:OnWaypointUpdated()
    elseif DXD.state.targetType == "waypoint" then
        -- User waypoint tracking was disabled
        -- Only clear if no other tracking took over
        if not C_SuperTrack.IsSuperTrackingAnything() then
            DXD:ClearTarget()
        end
    end
end

------------------------------------------------------------------------
-- PROGRAMMATIC WAYPOINT SETTING
------------------------------------------------------------------------

--- Set a waypoint from external input (TomTom format, etc.)
-- @param mapID the map ID
-- @param x map X (0-1)
-- @param y map Y (0-1)
-- @param name optional name
-- @param targetType optional type override
function WaypointTracker:SetExternalWaypoint(mapID, x, y, name, targetType)
    if not mapID or not x or not y then return end

    -- Set in WoW's system
    local uiMapPoint = UiMapPoint.CreateFromCoordinates(mapID, x, y)
    if uiMapPoint then
        C_Map.SetUserWaypoint(uiMapPoint)
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end

    -- Set in our system
    DXD:SetTarget(mapID, x, y, targetType or "waypoint", name)
end

--- Clear the current waypoint
function WaypointTracker:ClearWaypoint()
    -- Clear WoW's user waypoint
    if C_Map.HasUserWaypoint() then
        C_Map.ClearUserWaypoint()
    end
    if C_SuperTrack.IsSuperTrackingUserWaypoint() then
        C_SuperTrack.SetSuperTrackedUserWaypoint(false)
    end

    if DXD.state.targetType == "waypoint" then
        DXD:ClearTarget()
    end
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function WaypointTracker:Initialize()
    -- Check for existing waypoint
    if C_Map.HasUserWaypoint() then
        C_Timer.After(0.5, function()
            self:OnWaypointUpdated()
        end)
    end

    DXD:Debug("WaypointTracker initialized")
end
