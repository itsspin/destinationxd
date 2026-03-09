------------------------------------------------------------------------
-- DestinationXD - ElevationTracker.lua
-- Z-coordinate tracking, elevation delta, distance decomposition
--
-- IMPORTANT: UnitPosition("player") returns Z=0 always in retail WoW.
-- We estimate elevation using C_Navigation.GetDistance() triangulation:
--   If navDist (3D) > dist2D, then verticalDist = sqrt(3D^2 - 2D^2)
-- This gives magnitude but not direction. We determine direction by
-- tracking whether moving uphill or downhill reduces the 3D distance.
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local ElevationTracker = {}
DXD:RegisterModule("ElevationTracker", ElevationTracker)

local Utils = DXD.Utils
local Config = DXD.Config

-- Update accumulator
local updateAccum

-- Z estimation state
local zEstimation = {
    lastNavDistance = nil,
    lastDist2D = nil,
    verticalDist = 0,       -- Estimated vertical distance (magnitude)
    zSign = 0,              -- -1 = below, 0 = unknown, 1 = above
    zConfidence = 0,        -- 0 = no data, 1 = confirmed
    movementSamples = {},   -- Track navDistance changes relative to 2D distance
    maxSamples = 20,
}

------------------------------------------------------------------------
-- Z SIGN DETERMINATION
------------------------------------------------------------------------

--- Determine the sign of elevation difference by tracking nav vs 2D distance
-- If navDistance decreases faster than dist2D when moving, the target
-- is roughly at our level. If navDistance decreases slower, there's a
-- vertical component. We can infer direction from movement patterns.
local function DetermineZSign()
    local samples = zEstimation.movementSamples
    if #samples < 4 then return zEstimation.zSign end

    -- Compare oldest and newest: check if vertical component is shrinking
    local oldest = samples[1]
    local newest = samples[#samples]

    if not oldest.navDist or not newest.navDist then return zEstimation.zSign end
    if not oldest.dist2D or not newest.dist2D then return zEstimation.zSign end

    local navChange = newest.navDist - oldest.navDist
    local dist2DChange = newest.dist2D - oldest.dist2D

    -- If we're getting closer in 2D but nav distance isn't decreasing as fast,
    -- the vertical component is significant
    if math.abs(dist2DChange) > 5 then
        local navRate = navChange / dist2DChange
        -- navRate close to 1 = mostly horizontal movement
        -- navRate < 1 = target has vertical component
        -- We can't reliably determine UP vs DOWN from this alone,
        -- but if the player can see the nav frame's vertical position...
    end

    -- Use C_Navigation state to help determine direction
    if C_Navigation and C_Navigation.GetFrame then
        local navFrame = C_Navigation.GetFrame()
        if navFrame and navFrame:IsShown() then
            local _, navY = navFrame:GetCenter()
            local screenHeight = GetScreenHeight()
            if navY and screenHeight then
                local relY = navY / screenHeight
                -- If nav indicator is in upper half of screen, target is above
                -- If in lower half, target is below
                if relY > 0.55 then
                    zEstimation.zSign = 1  -- above
                elseif relY < 0.45 then
                    zEstimation.zSign = -1  -- below
                else
                    zEstimation.zSign = 0  -- roughly level
                end
            end
        end
    end

    return zEstimation.zSign
end

------------------------------------------------------------------------
-- ELEVATION ESTIMATION
------------------------------------------------------------------------

local function EstimateElevation()
    local state = DXD.state
    if not state.hasTarget then return end

    -- Triangulation using C_Navigation.GetDistance()
    -- This gives us the approximate 3D distance to the supertracked waypoint
    local navDistance = nil
    if C_Navigation and C_Navigation.GetDistance then
        navDistance = C_Navigation.GetDistance()
    end

    -- Calculate 2D distance from world coordinates
    local dist2D = 0
    if state.targetWorldX and state.targetWorldY and state.playerX and state.playerY then
        dist2D = Utils.Distance2D(state.playerX, state.playerY, state.targetWorldX, state.targetWorldY)
    end

    state.distance2D = dist2D
    state.distanceHorizontal = dist2D

    -- Track movement samples for sign determination
    local now = GetTime()
    table.insert(zEstimation.movementSamples, {
        time = now,
        navDist = navDistance,
        dist2D = dist2D,
    })
    while #zEstimation.movementSamples > zEstimation.maxSamples do
        table.remove(zEstimation.movementSamples, 1)
    end

    -- Estimate vertical distance via triangulation
    if navDistance and navDistance > 0 and dist2D > 0 then
        if navDistance > dist2D + 1 then
            -- vertical = sqrt(3D^2 - 2D^2)
            zEstimation.verticalDist = math.sqrt(navDistance * navDistance - dist2D * dist2D)
            zEstimation.zConfidence = 0.7
        else
            -- Nav distance roughly equals 2D distance -> same level
            zEstimation.verticalDist = 0
            zEstimation.zConfidence = 0.6
        end

        -- Use nav distance as the authoritative 3D distance
        state.distance3D = navDistance
        zEstimation.lastNavDistance = navDistance
    elseif dist2D > 0 then
        -- No nav distance available, use 2D as approximation
        state.distance3D = dist2D
        zEstimation.verticalDist = 0
    end

    -- Determine sign (above/below)
    DetermineZSign()

    -- Apply estimated elevation data
    state.distanceVertical = zEstimation.verticalDist
    state.elevationDelta = zEstimation.verticalDist * (zEstimation.zSign >= 0 and 1 or -1)

    -- Classify elevation state with hysteresis
    local threshold = DXD.db and DXD.db.verticalTolerance or 8
    local currentState = state.elevationState
    local vertDist = zEstimation.verticalDist
    local hysteresis = 2

    if vertDist < threshold then
        -- Within tolerance = same level regardless of sign
        if currentState ~= "level" and vertDist < (threshold - hysteresis) then
            state.elevationState = "level"
        elseif currentState == "level" or currentState == nil then
            state.elevationState = "level"
        end
    else
        -- Significant vertical distance
        if zEstimation.zSign > 0 then
            state.elevationState = "above"
        elseif zEstimation.zSign < 0 then
            state.elevationState = "below"
        else
            -- Unknown direction, keep previous or default to level
            if currentState ~= "above" and currentState ~= "below" then
                state.elevationState = "level"
            end
        end
    end

    -- Bearing to target (for direction arrow)
    if state.targetWorldX and state.targetWorldY and state.playerX and state.playerY then
        state.bearing = Utils.Bearing(state.playerX, state.playerY,
            state.targetWorldX, state.targetWorldY)
    end

    zEstimation.lastDist2D = dist2D
end

------------------------------------------------------------------------
-- PUBLIC API
------------------------------------------------------------------------

function ElevationTracker:GetElevationInfo()
    local state = DXD.state
    return {
        delta = state.elevationDelta,
        state = state.elevationState,
        horizontal = state.distanceHorizontal,
        vertical = state.distanceVertical,
        distance3D = state.distance3D,
        confidence = zEstimation.zConfidence,
    }
end

function ElevationTracker:OnTargetChanged()
    zEstimation.verticalDist = 0
    zEstimation.zConfidence = 0
    zEstimation.zSign = 0
    zEstimation.lastNavDistance = nil
    zEstimation.lastDist2D = nil
    wipe(zEstimation.movementSamples)
end

function ElevationTracker:OnTargetCleared()
    zEstimation.verticalDist = 0
    zEstimation.zConfidence = 0
    zEstimation.zSign = 0
    zEstimation.lastNavDistance = nil
    zEstimation.lastDist2D = nil
    wipe(zEstimation.movementSamples)
end

------------------------------------------------------------------------
-- UPDATE
------------------------------------------------------------------------

function ElevationTracker:OnUpdate(elapsed)
    if not updateAccum then return end
    if not updateAccum:ShouldUpdate(elapsed) then return end

    EstimateElevation()
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function ElevationTracker:Initialize()
    updateAccum = Utils.CreateAccumulator(Config.UPDATE_RATES.ELEVATION)
    DXD:Debug("ElevationTracker initialized")
end
