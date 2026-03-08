------------------------------------------------------------------------
-- DestinationXD - BeaconAnimations.lua
-- Pulse, glow, proximity fading, arrival bloom animations
-- Beam stays full-height; proximity handled via alpha fade (not shrink)
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local BeaconAnimations = {}
DXD:RegisterModule("BeaconAnimations", BeaconAnimations)

local Utils = DXD.Utils
local Config = DXD.Config

-- Animation state
local animState = {
    pulseTime = 0,
    bobTime = 0,
    arrivalPhase = nil,     -- nil, "bloom", "fade"
    arrivalStart = 0,
    bloomScale = 1,
    bloomAlpha = 1,
    morphProgress = 0,      -- 0 = full beam, 1 = full firefly
    targetMorphProgress = 0,
    idleAlpha = 1,
    targetIdleAlpha = 1,
}

------------------------------------------------------------------------
-- PULSE ANIMATION
------------------------------------------------------------------------

function BeaconAnimations:GetPulseAlpha(distance)
    local cfg = Config.BEACON
    local anim = Config.ANIMATION

    local period = anim.BEACON_PULSE_PERIOD
    if distance and distance < cfg.MEDIUM_DISTANCE then
        local t = Utils.Remap(distance, cfg.CLOSE_DISTANCE, cfg.MEDIUM_DISTANCE, 0, 1)
        period = Utils.Lerp(anim.BEACON_PULSE_CLOSE, anim.BEACON_PULSE_PERIOD, t)
    end

    return Utils.SineWave(animState.pulseTime, period, cfg.PULSE_MIN_ALPHA, cfg.PULSE_MAX_ALPHA)
end

------------------------------------------------------------------------
-- PROXIMITY MORPH (beam to firefly at close range)
------------------------------------------------------------------------

function BeaconAnimations:UpdateMorph(distance, elapsed)
    local cfg = Config.BEACON

    if not distance then
        animState.targetMorphProgress = 0
    elseif distance < cfg.CLOSE_DISTANCE then
        animState.targetMorphProgress = 1.0
    elseif distance < cfg.MEDIUM_DISTANCE then
        animState.targetMorphProgress = Utils.Remap(distance, cfg.MEDIUM_DISTANCE, cfg.CLOSE_DISTANCE, 0, 1)
    else
        animState.targetMorphProgress = 0.0
    end

    local speed = 3.0 * elapsed
    if animState.morphProgress < animState.targetMorphProgress then
        animState.morphProgress = math.min(animState.morphProgress + speed, animState.targetMorphProgress)
    else
        animState.morphProgress = math.max(animState.morphProgress - speed, animState.targetMorphProgress)
    end
end

function BeaconAnimations:GetMorphProgress()
    return animState.morphProgress
end

------------------------------------------------------------------------
-- PROXIMITY ALPHA (clean fade as player approaches)
------------------------------------------------------------------------

--- Get alpha multiplier based on distance - fades beam cleanly at close range
-- Instead of shrinking the beam, we fade it out smoothly
function BeaconAnimations:GetProximityAlpha(distance)
    if not distance then return 1.0 end
    local cfg = Config.BEACON

    if distance < cfg.CLOSE_DISTANCE then
        -- Very close: beam fading out, firefly taking over
        return Utils.Remap(distance, 0, cfg.CLOSE_DISTANCE, 0, 0.4)
    elseif distance < cfg.CLOSE_DISTANCE * 3 then
        -- Transitional range: beam becoming fully visible
        return Utils.Remap(distance, cfg.CLOSE_DISTANCE, cfg.CLOSE_DISTANCE * 3, 0.4, 1.0)
    end
    return 1.0
end

------------------------------------------------------------------------
-- FIREFLY BOB
------------------------------------------------------------------------

function BeaconAnimations:GetBobOffset()
    local cfg = Config.BEACON
    return math.sin(animState.bobTime * math.pi * 2 / cfg.BOB_PERIOD) * cfg.BOB_AMPLITUDE
end

------------------------------------------------------------------------
-- ARRIVAL BLOOM
------------------------------------------------------------------------

function BeaconAnimations:TriggerArrival()
    animState.arrivalPhase = "bloom"
    animState.arrivalStart = GetTime()
    animState.bloomScale = 1
    animState.bloomAlpha = 1
end

function BeaconAnimations:UpdateArrival()
    if not animState.arrivalPhase then
        return 1, 1, false
    end

    local anim = Config.ANIMATION
    local now = GetTime()
    local elapsed = now - animState.arrivalStart

    if animState.arrivalPhase == "bloom" then
        local t = elapsed / anim.BEACON_ARRIVE_BLOOM
        if t >= 1 then
            animState.arrivalPhase = "fade"
            animState.arrivalStart = now
            animState.bloomScale = 2
            t = 1
        end
        local eased = Utils.EaseOutCubic(t)
        animState.bloomScale = Utils.Lerp(1, 2, eased)
        animState.bloomAlpha = 1
        return animState.bloomScale, animState.bloomAlpha, false

    elseif animState.arrivalPhase == "fade" then
        local t = elapsed / anim.BEACON_FADE_OUT
        if t >= 1 then
            animState.arrivalPhase = nil
            return 2, 0, true
        end
        local eased = Utils.EaseInOutCubic(t)
        animState.bloomAlpha = Utils.Lerp(1, 0, eased)
        return 2, animState.bloomAlpha, false
    end

    return 1, 1, false
end

function BeaconAnimations:IsArrivalPlaying()
    return animState.arrivalPhase ~= nil
end

------------------------------------------------------------------------
-- IDLE FADE
------------------------------------------------------------------------

function BeaconAnimations:UpdateIdleFade(isMoving, elapsed)
    if isMoving then
        animState.targetIdleAlpha = 1.0
    else
        animState.targetIdleAlpha = 0.45
    end

    local speed = elapsed / (isMoving and 0.2 or Config.ANIMATION.ELEVATION_IDLE_FADE)
    if animState.idleAlpha < animState.targetIdleAlpha then
        animState.idleAlpha = math.min(animState.idleAlpha + speed, animState.targetIdleAlpha)
    else
        animState.idleAlpha = math.max(animState.idleAlpha - speed, animState.targetIdleAlpha)
    end
end

function BeaconAnimations:GetIdleAlpha()
    return animState.idleAlpha
end

------------------------------------------------------------------------
-- BEAM HEIGHT - always extends to top of screen
------------------------------------------------------------------------

--- Beam height: always fills from base to top of screen
-- No distance-based shrinking; proximity is handled by alpha fade
function BeaconAnimations:GetBeamHeight(distance, screenY)
    local screenHeight = GetScreenHeight()
    local baseY = math.max(screenY or 0, 0)
    local fullHeight = screenHeight - baseY + 20  -- slight overshoot past top

    if fullHeight < 2 then return 0 end
    return fullHeight
end

--- Beam width stays constant (thin core)
function BeaconAnimations:GetBeamWidth(distance)
    local cfg = Config.BEACON
    if not distance then return cfg.BEAM_WIDTH_BASE end

    -- Slightly thinner at extreme distance for perspective
    if distance > cfg.FAR_DISTANCE * 2 then
        return cfg.BEAM_WIDTH_BASE * 0.7
    end
    return cfg.BEAM_WIDTH_BASE
end

--- Glow width stays constant
function BeaconAnimations:GetGlowWidth(distance)
    local cfg = Config.BEACON
    return cfg.GLOW_WIDTH_BASE
end

------------------------------------------------------------------------
-- CHEVRON ANIMATION (elevation indicators on beam)
------------------------------------------------------------------------

local chevronOffset = 0

function BeaconAnimations:GetChevronOffset()
    return chevronOffset
end

------------------------------------------------------------------------
-- UPDATE
------------------------------------------------------------------------

function BeaconAnimations:OnUpdate(elapsed)
    animState.pulseTime = animState.pulseTime + elapsed
    animState.bobTime = animState.bobTime + elapsed

    local elevState = DXD.state.elevationState
    if elevState == "above" then
        chevronOffset = (chevronOffset + elapsed * 15) % 40
    elseif elevState == "below" then
        chevronOffset = (chevronOffset - elapsed * 15) % 40
    end
end

function BeaconAnimations:Reset()
    animState.pulseTime = 0
    animState.bobTime = 0
    animState.arrivalPhase = nil
    animState.morphProgress = 0
    animState.targetMorphProgress = 0
    animState.idleAlpha = 1
    animState.targetIdleAlpha = 1
    chevronOffset = 0
end

function BeaconAnimations:Initialize()
    DXD:Debug("BeaconAnimations initialized")
end
