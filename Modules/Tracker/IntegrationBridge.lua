------------------------------------------------------------------------
-- DestinationXD - IntegrationBridge.lua
-- TomTom and HandyNotes compatibility layer
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local IntegrationBridge = {}
DXD:RegisterModule("IntegrationBridge", IntegrationBridge)

local Utils = DXD.Utils

-- Integration state
local tomtomHooked = false
local handyNotesHooked = false

------------------------------------------------------------------------
-- TOMTOM COMPATIBILITY
------------------------------------------------------------------------

local function HookTomTom()
    if not DXD.db.tomtomCompat then return end
    if tomtomHooked then return end

    -- Check if TomTom is loaded
    if not TomTom then return end

    DXD:Debug("TomTom detected, hooking...")

    -- Hook TomTom's waypoint setting
    if TomTom.AddWaypoint then
        hooksecurefunc(TomTom, "AddWaypoint", function(self, mapID, x, y, opts)
            if not DXD.db.tomtomCompat then return end

            local name = opts and opts.title or "TomTom Waypoint"
            DXD:SetTarget(mapID, x, y, "tomtom", name)
            DXD:Debug("TomTom waypoint intercepted: " .. tostring(name))
        end)
    end

    -- Hook TomTom's waypoint removal
    if TomTom.RemoveWaypoint then
        hooksecurefunc(TomTom, "RemoveWaypoint", function(self, uid)
            if not DXD.db.tomtomCompat then return end
            if DXD.state.targetType == "tomtom" then
                DXD:ClearTarget()
            end
        end)
    end

    tomtomHooked = true
    DXD:Debug("TomTom hooks installed")
end

------------------------------------------------------------------------
-- HANDYNOTES COMPATIBILITY
------------------------------------------------------------------------

local function HookHandyNotes()
    if not DXD.db.handyNotesCompat then return end
    if handyNotesHooked then return end

    -- Check if HandyNotes is loaded
    if not HandyNotes then return end

    DXD:Debug("HandyNotes detected, hooking...")

    -- HandyNotes uses a pin system; we hook into the waypoint creation
    if HandyNotes.SetWaypoint then
        hooksecurefunc(HandyNotes, "SetWaypoint", function(self, mapID, x, y, name)
            if not DXD.db.handyNotesCompat then return end
            DXD:SetTarget(mapID, x, y, "waypoint", name or "HandyNotes Pin")
            DXD:Debug("HandyNotes waypoint intercepted")
        end)
    end

    handyNotesHooked = true
    DXD:Debug("HandyNotes hooks installed")
end

------------------------------------------------------------------------
-- PUBLIC API
------------------------------------------------------------------------

--- Check if TomTom is available
function IntegrationBridge:IsTomTomAvailable()
    return TomTom ~= nil
end

--- Check if HandyNotes is available
function IntegrationBridge:IsHandyNotesAvailable()
    return HandyNotes ~= nil
end

--- Get integration status
function IntegrationBridge:GetStatus()
    return {
        tomtom = {
            available = self:IsTomTomAvailable(),
            hooked = tomtomHooked,
            enabled = DXD.db.tomtomCompat,
        },
        handyNotes = {
            available = self:IsHandyNotesAvailable(),
            hooked = handyNotesHooked,
            enabled = DXD.db.handyNotesCompat,
        },
    }
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function IntegrationBridge:Initialize()
    -- Delay integration hooks to ensure other addons are loaded
    C_Timer.After(2, function()
        HookTomTom()
        HookHandyNotes()
    end)

    DXD:Debug("IntegrationBridge initialized")
end
