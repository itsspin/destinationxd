------------------------------------------------------------------------
-- DestinationXD - ProximityManager.lua
-- Smart Z-aware arrival detection + obstruction detection
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local ProximityManager = {}
DXD:RegisterModule("ProximityManager", ProximityManager)

local Utils = DXD.Utils
local Config = DXD.Config

-- Update accumulators
local proximityAccum
local obstructionAccum

-- Arrival state
local wasClose = false
local arrivalTriggered = false

-- Obstruction detection state
local obstructionSamples = {}
local isObstructed = false
local obstructionStartTime = 0

------------------------------------------------------------------------
-- ARRIVAL DETECTION
------------------------------------------------------------------------

local function CheckArrival()
    local state = DXD.state
    if not state.hasTarget then return end
    if arrivalTriggered then return end

    local dist2D = state.distance2D
    local zDelta = math.abs(state.elevationDelta)
    local arrivalDist = DXD.db.arrivalDistance or Config.BEACON.CLOSE_DISTANCE
    local zThreshold = DXD.db.verticalTolerance or Config.ELEVATION.Z_ARRIVAL_THRESHOLD

    -- Proximity sound cue at 10 yards
    if dist2D < 10 and not wasClose then
        wasClose = true
        if DXD.db.playSounds then
            -- Play proximity approach sound
            PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_SUPER_TRACK_ON or 170148, "Master")
        end
    elseif dist2D > 15 then
        wasClose = false
    end

    -- Arrival check: 2D distance AND Z tolerance
    local arrived = (dist2D < arrivalDist) and (zDelta < zThreshold)

    if arrived then
        arrivalTriggered = true
        DXD:Debug("Arrived at destination!")

        -- Trigger arrival visuals
        local beacon = DXD:GetModule("Beacon")
        if beacon then
            beacon:TriggerArrival()
        end

        -- Play arrival sound
        if DXD.db.playSounds then
            PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_CHAT_SHARE or 170147, "Master")
        end

        -- Auto-clear if enabled
        if DXD.db.autoClearOnArrival then
            C_Timer.After(1.5, function()
                if arrivalTriggered then  -- Still in arrival state
                    DXD:ClearTarget()
                    -- Clear supertrack user waypoint
                    if C_SuperTrack.IsSuperTrackingUserWaypoint() then
                        C_SuperTrack.SetSuperTrackedUserWaypoint(false)
                    end
                end
            end)
        end
    end
end

------------------------------------------------------------------------
-- OBSTRUCTION DETECTION
------------------------------------------------------------------------

local function CheckObstruction()
    local state = DXD.state
    if not state.hasTarget then
        isObstructed = false
        state.isObstructed = false
        return
    end

    local cfg = Config.OBSTRUCTION
    local now = GetTime()

    -- Add sample
    table.insert(obstructionSamples, {
        time = now,
        distance = state.distance3D,
        bearing = state.bearing,
        playerFacing = state.playerFacing,
    })

    -- Trim old samples
    while #obstructionSamples > 0 and (now - obstructionSamples[1].time) > cfg.SAMPLE_WINDOW do
        table.remove(obstructionSamples, 1)
    end

    -- Need enough samples
    if #obstructionSamples < 4 then
        isObstructed = false
        state.isObstructed = false
        return
    end

    -- Check if player is moving toward target but distance isn't decreasing
    local oldest = obstructionSamples[1]
    local newest = obstructionSamples[#obstructionSamples]

    -- Is the player moving toward the target?
    -- Check if player facing is within ±30° of bearing to target
    local facingDelta = Utils.AngleDelta(newest.playerFacing, newest.bearing)
    local movingToward = math.abs(facingDelta) < (cfg.BEARING_THRESHOLD * math.pi / 180)

    -- Check if player is actually moving (not standing still)
    local isMoving = state.playerMoving

    -- Is the distance not decreasing?
    local distanceDelta = newest.distance - oldest.distance
    local distanceStalled = distanceDelta > -cfg.DISTANCE_STALL_THRESHOLD

    -- Obstruction = moving toward target + distance stalled
    local nowObstructed = movingToward and isMoving and distanceStalled
        and (now - oldest.time) >= cfg.SAMPLE_WINDOW * 0.8

    if nowObstructed and not isObstructed then
        isObstructed = true
        obstructionStartTime = now
        DXD:Debug("Obstruction detected!")
    elseif not nowObstructed and isObstructed then
        -- Allow some persistence (don't flicker)
        if (now - obstructionStartTime) > 2 then
            isObstructed = false
        end
    end

    state.isObstructed = isObstructed
end

------------------------------------------------------------------------
-- PUBLIC API
------------------------------------------------------------------------

function ProximityManager:IsObstructed()
    return isObstructed
end

function ProximityManager:GetObstructionMessage()
    if not isObstructed then return nil end

    local state = DXD.state
    if state.elevationState == "above" then
        return "Look for a way up"
    elseif state.elevationState == "below" then
        return "Look for a way down"
    else
        return "Find an entrance nearby"
    end
end

function ProximityManager:OnTargetChanged()
    arrivalTriggered = false
    wasClose = false
    isObstructed = false
    wipe(obstructionSamples)
end

function ProximityManager:OnTargetCleared()
    arrivalTriggered = false
    wasClose = false
    isObstructed = false
    wipe(obstructionSamples)
end

------------------------------------------------------------------------
-- UPDATE
------------------------------------------------------------------------

function ProximityManager:OnUpdate(elapsed)
    if not proximityAccum or not obstructionAccum then return end

    if proximityAccum:ShouldUpdate(elapsed) then
        CheckArrival()
    end

    if obstructionAccum:ShouldUpdate(elapsed) then
        CheckObstruction()
    end
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function ProximityManager:Initialize()
    proximityAccum = Utils.CreateAccumulator(Config.UPDATE_RATES.DISTANCE)
    obstructionAccum = Utils.CreateAccumulator(Config.UPDATE_RATES.OBSTRUCTION)
    DXD:Debug("ProximityManager initialized")
end
