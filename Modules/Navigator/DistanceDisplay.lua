------------------------------------------------------------------------
-- DestinationXD - DistanceDisplay.lua
-- Decomposed distance display (horizontal + vertical)
-- Integrated into DirectionArrow, this module provides the data layer
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local DistanceDisplay = {}
DXD:RegisterModule("DistanceDisplay", DistanceDisplay)

local Utils = DXD.Utils
local Config = DXD.Config

------------------------------------------------------------------------
-- FORMATTED DISTANCE INFO
------------------------------------------------------------------------

--- Get formatted distance information
-- @return table with display strings
function DistanceDisplay:GetFormattedInfo()
    local state = DXD.state
    if not state.hasTarget then return nil end

    local info = {
        total = Utils.FormatDistance(state.distance3D),
        horizontal = Utils.FormatDistance(state.distanceHorizontal),
        vertical = Utils.FormatDistance(state.distanceVertical),
        elevationState = state.elevationState,
        elevationDelta = state.elevationDelta,
    }

    -- ETA
    local eta = Utils.EstimateETA(state.distance3D)
    info.eta = eta and Utils.FormatETA(eta) or nil

    -- Decomposed string
    if state.elevationState ~= "level" and DXD.db.showDecomposedDistance then
        local chevron = state.elevationState == "above" and "\226\150\178" or "\226\150\188"
        info.decomposed = "\226\134\146 " .. info.horizontal .. "  " .. chevron .. " " .. info.vertical
    else
        info.decomposed = "\226\134\146 " .. info.total
    end

    return info
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function DistanceDisplay:Initialize()
    DXD:Debug("DistanceDisplay initialized")
end
