------------------------------------------------------------------------
-- DestinationXD - PinpointFormatting.lua
-- Context-aware text/icon formatting for in-world display
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local PinpointFormatting = {}
DXD:RegisterModule("PinpointFormatting", PinpointFormatting)

local Config = DXD.Config
local Utils = DXD.Utils

------------------------------------------------------------------------
-- FORMATTING
------------------------------------------------------------------------

--- Format the pinpoint title line
function PinpointFormatting:GetTitle()
    local state = DXD.state
    if not state.hasTarget then return nil end

    local name = state.targetName
    if not name then
        if state.targetType == "corpse" then
            return "Your Corpse"
        elseif state.targetType == "travel" then
            return "Route Step"
        else
            return "Waypoint"
        end
    end

    -- Truncate long names
    if #name > 30 then
        name = name:sub(1, 27) .. "..."
    end

    return name
end

--- Format the pinpoint subtitle line
function PinpointFormatting:GetSubtitle()
    local state = DXD.state
    if not state.hasTarget then return nil end

    local desc = state.targetDescription
    if desc then
        if #desc > 40 then
            desc = desc:sub(1, 37) .. "..."
        end
        return desc
    end

    return nil
end

--- Format distance + elevation info line
function PinpointFormatting:GetInfoLine()
    local state = DXD.state
    if not state.hasTarget then return nil end

    local dist = Utils.FormatDistance(state.distance3D)
    local eta = Utils.EstimateETA(state.distance3D)
    local etaStr = eta and (" " .. Utils.FormatETA(eta)) or ""

    if state.elevationState ~= "level" then
        local chevron = state.elevationState == "above" and "\226\150\178" or "\226\150\188"
        local vertDist = Utils.FormatDistance(state.distanceVertical)
        return dist .. "  " .. chevron .. vertDist .. etaStr
    end

    return dist .. etaStr
end

--- Get the type label text
function PinpointFormatting:GetTypeLabel()
    local state = DXD.state
    local labels = {
        quest = "quest",
        waypoint = "waypoint",
        corpse = "corpse",
        travel = "route",
        tomtom = "tomtom",
        dungeon = "dungeon",
        flight = "flight",
    }
    return labels[state.targetType] or ""
end

--- Get the color for the type label
function PinpointFormatting:GetTypeLabelColor()
    return DXD:GetBeaconColor()
end

function PinpointFormatting:Initialize()
    DXD:Debug("PinpointFormatting initialized")
end
