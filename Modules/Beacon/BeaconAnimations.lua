------------------------------------------------------------------------
-- DestinationXD - BeaconAnimations.lua
-- Pulse, glow, proximity morphing, arrival bloom animations
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

--- Calculate the current pulse alpha for the beacon breathing
-- @param distance distance to target in yards
-- @return alpha value (0-1)
function BeaconAnimations:GetPulseAlpha(distance)
    local cfg = Config.BEACON
    local anim = Config.ANIMATION

    local period = anim.BEACON_PULSE_PERIOD
    if distance and distance < cfg.MEDIUM_DISTANCE then
        -- Faster pulse when close
        local t = Utils.Remap(distance, cfg.CLOSE_DISTANCE, cfg.MEDIUM_DISTANCE, 0, 1)
        period = Utils.Lerp(anim.BEACON_PULSE_CLOSE, anim.BEACON_PULSE_PERIOD, t)
    end

    return Utils.SineWave(animState.pulseTime, period, cfg.PULSE_MIN_ALPHA, cfg.PULSE_MAX_ALPHA)
end

------------------------------------------------------------------------
-- PROXIMITY MORPH
------------------------------------------------------------------------

--- Update the beam-to-firefly morph based on distance
-- @param distance distance in yards
-- @param elapsed frame time
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

    -- Smooth transition
    local speed = 3.0 * elapsed
    if animState.morphProgress < animState.targetMorphProgress then
        animState.morphProgress = math.min(animState.morphProgress + speed, animState.targetMorphProgress)
    else
        animState.morphProgress = math.max(animState.morphProgress - speed, animState.targetMorphProgress)
    end
end

--- Get current morph progress (0 = beam, 1 = firefly)
function BeaconAnimations:GetMorphProgress()
    return animState.morphProgress
end

------------------------------------------------------------------------
-- FIREFLY BOB
------------------------------------------------------------------------

--- Get the vertical bob offset for the close-range firefly
function BeaconAnimations:GetBobOffset()
    local cfg = Config.BEACON
    return math.sin(animState.bobTime * math.pi * 2 / cfg.BOB_PERIOD) * cfg.BOB_AMPLITUDE
end

------------------------------------------------------------------------
-- ARRIVAL BLOOM
------------------------------------------------------------------------

--- Trigger the arrival bloom animation
function BeaconAnimations:TriggerArrival()
    animState.arrivalPhase = "bloom"
    animState.arrivalStart = GetTime()
    animState.bloomScale = 1
    animState.bloomAlpha = 1
end

--- Update arrival animation state
-- @return scale, alpha, isComplete
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

--- Check if arrival animation is playing
function BeaconAnimations:IsArrivalPlaying()
    return animState.arrivalPhase ~= nil
end

------------------------------------------------------------------------
-- IDLE FADE
------------------------------------------------------------------------

--- Update idle opacity (fades to low alpha when not moving)
-- @param isMoving whether the player is moving
-- @param elapsed frame time
function BeaconAnimations:UpdateIdleFade(isMoving, elapsed)
    if isMoving then
        animState.targetIdleAlpha = 1.0
    else
        animState.targetIdleAlpha = 0.40
    end

    local speed = elapsed / (isMoving and 0.2 or Config.ANIMATION.ELEVATION_IDLE_FADE)
    if animState.idleAlpha < animState.targetIdleAlpha then
        animState.idleAlpha = math.min(animState.idleAlpha + speed, animState.targetIdleAlpha)
    else
        animState.idleAlpha = math.max(animState.idleAlpha - speed, animState.targetIdleAlpha)
    end
end

--- Get current idle alpha
function BeaconAnimations:GetIdleAlpha()
    return animState.idleAlpha
end

------------------------------------------------------------------------
-- BEAM HEIGHT SCALING
------------------------------------------------------------------------

--- Calculate beam height based on distance and screen position
-- @param distance yards to target
-- @param screenY base Y position on screen (nil = use full screen height)
-- @return height in pixels (extends from screenY to top of screen)
function BeaconAnimations:GetBeamHeight(distance, screenY)
    local cfg = Config.BEACON

    if not distance or distance < cfg.CLOSE_DISTANCE then
        return 0
    end

    -- Beam extends from the base position to the top of the screen
    local screenHeight = GetScreenHeight()
    local baseY = screenY or (screenHeight * 0.35)
    local fullHeight = screenHeight - baseY

    if fullHeight < 10 then return 0 end

    if distance > cfg.FAR_DISTANCE then
        return fullHeight
    elseif distance > cfg.MEDIUM_DISTANCE then
        local t = Utils.Remap(distance, cfg.MEDIUM_DISTANCE, cfg.FAR_DISTANCE, 0.5, 1.0)
        return fullHeight * t
    else
        -- Close: shrinking beam before morphing to firefly
        local t = Utils.Remap(distance, cfg.CLOSE_DISTANCE, cfg.MEDIUM_DISTANCE, 0, 0.5)
        return fullHeight * t
    end
end

--- Calculate beam width based on distance
function BeaconAnimations:GetBeamWidth(distance)
    local cfg = Config.BEACON
    if not distance then return cfg.BEAM_WIDTH_BASE end

    -- Beam stays thin, just slight perspective scaling
    if distance > cfg.FAR_DISTANCE then
        return cfg.BEAM_WIDTH_BASE * 0.8
    end
    return cfg.BEAM_WIDTH_BASE
end

--- Calculate glow width
function BeaconAnimations:GetGlowWidth(distance)
    local cfg = Config.BEACON
    local baseGlow = cfg.GLOW_WIDTH_BASE

    if not distance then return baseGlow end

    -- Glow intensifies slightly as you approach
    if distance < cfg.MEDIUM_DISTANCE then
        local t = Utils.Remap(distance, cfg.CLOSE_DISTANCE, cfg.MEDIUM_DISTANCE, 1.5, 1.0)
        return baseGlow * t
    end
    return baseGlow
end

------------------------------------------------------------------------
-- CHEVRON ANIMATION (elevation indicators on beam)
------------------------------------------------------------------------

local chevronOffset = 0

--- Get chevron drift offset for beam elevation indicators
function BeaconAnimations:GetChevronOffset()
    return chevronOffset
end

------------------------------------------------------------------------
-- UPDATE
------------------------------------------------------------------------

function BeaconAnimations:OnUpdate(elapsed)
    animState.pulseTime = animState.pulseTime + elapsed
    animState.bobTime = animState.bobTime + elapsed

    -- Chevron drift (slow upward or downward movement)
    local elevState = DXD.state.elevationState
    if elevState == "above" then
        chevronOffset = (chevronOffset + elapsed * 15) % 40  -- drift upward
    elseif elevState == "below" then
        chevronOffset = (chevronOffset - elapsed * 15) % 40  -- drift downward
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
