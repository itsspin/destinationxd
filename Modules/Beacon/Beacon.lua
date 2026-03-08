------------------------------------------------------------------------
-- DestinationXD - Beacon.lua
-- The in-world waypoint beam - the visual centerpiece
-- A thin, luminous laser beam projected at the destination
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local Beacon = {}
DXD:RegisterModule("Beacon", Beacon)

local Utils = DXD.Utils
local Config = DXD.Config
local Pool = DXD:GetModule("BeaconPool")
local Anim = DXD:GetModule("BeaconAnimations")

-- Update accumulator
local updateAccum

-- Beacon visual frames
local beamFrame      -- The main beam shaft
local glowFrame      -- Glow overlay around the beam
local baseFrame      -- Ground marker
local fireflyFrame   -- Close-range floating point
local chevronFrames = {} -- Elevation chevrons on the beam

-- State
local isVisible = false
local currentColor = nil
local fadeAlpha = 0
local targetFadeAlpha = 0

------------------------------------------------------------------------
-- FRAME CREATION
------------------------------------------------------------------------

local function CreateBeaconFrames()
    -- Main beam container
    beamFrame = CreateFrame("Frame", "DXDBeaconBeam", UIParent)
    beamFrame:SetFrameStrata("BACKGROUND")
    beamFrame:SetFrameLevel(1)
    beamFrame:Hide()

    -- Beam shaft texture (thin vertical line)
    beamFrame.shaft = beamFrame:CreateTexture(nil, "ARTWORK")
    beamFrame.shaft:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    beamFrame.shaft:SetBlendMode("ADD")
    beamFrame.shaft:SetPoint("BOTTOM")

    -- Glow aura (soft gaussian feel via layered textures)
    beamFrame.glow = beamFrame:CreateTexture(nil, "ARTWORK", nil, -1)
    beamFrame.glow:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    beamFrame.glow:SetBlendMode("ADD")
    beamFrame.glow:SetAlpha(0.15)
    beamFrame.glow:SetPoint("BOTTOM")

    -- Secondary glow layer (wider, more transparent)
    beamFrame.glow2 = beamFrame:CreateTexture(nil, "ARTWORK", nil, -2)
    beamFrame.glow2:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    beamFrame.glow2:SetBlendMode("ADD")
    beamFrame.glow2:SetAlpha(0.06)
    beamFrame.glow2:SetPoint("BOTTOM")

    -- Base ground glow
    baseFrame = CreateFrame("Frame", "DXDBeaconBase", UIParent)
    baseFrame:SetFrameStrata("BACKGROUND")
    baseFrame:SetFrameLevel(0)
    baseFrame:SetSize(16, 16)
    baseFrame:Hide()

    baseFrame.glow = baseFrame:CreateTexture(nil, "ARTWORK")
    baseFrame.glow:SetTexture("Interface\\COMMON\\Indicator-Yellow")
    baseFrame.glow:SetBlendMode("ADD")
    baseFrame.glow:SetAlpha(0.3)
    baseFrame.glow:SetAllPoints()

    -- Firefly point (close range)
    fireflyFrame = CreateFrame("Frame", "DXDBeaconFirefly", UIParent)
    fireflyFrame:SetFrameStrata("BACKGROUND")
    fireflyFrame:SetFrameLevel(2)
    fireflyFrame:SetSize(10, 10)
    fireflyFrame:Hide()

    fireflyFrame.dot = fireflyFrame:CreateTexture(nil, "ARTWORK")
    fireflyFrame.dot:SetTexture("Interface\\COMMON\\Indicator-Yellow")
    fireflyFrame.dot:SetBlendMode("ADD")
    fireflyFrame.dot:SetAllPoints()

    -- Elevation chevrons (pre-create a few)
    for i = 1, 5 do
        local cf = CreateFrame("Frame", "DXDChevron" .. i, UIParent)
        cf:SetFrameStrata("BACKGROUND")
        cf:SetFrameLevel(3)
        cf:SetSize(10, 10)
        cf:Hide()

        cf.text = cf:CreateFontString(nil, "OVERLAY")
        cf.text:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        cf.text:SetPoint("CENTER")
        cf.text:SetShadowColor(0, 0, 0, 0.5)
        cf.text:SetShadowOffset(1, -1)
        chevronFrames[i] = cf
    end
end

------------------------------------------------------------------------
-- COLOR APPLICATION
------------------------------------------------------------------------

local function ApplyBeaconColor(color)
    if not color then return end
    currentColor = color

    -- Beam shaft
    if beamFrame and beamFrame.shaft then
        beamFrame.shaft:SetVertexColor(color.r, color.g, color.b, color.a or 0.85)
    end
    -- Glow layers
    if beamFrame and beamFrame.glow then
        beamFrame.glow:SetVertexColor(color.r, color.g, color.b, 0.15)
    end
    if beamFrame and beamFrame.glow2 then
        beamFrame.glow2:SetVertexColor(color.r, color.g, color.b, 0.06)
    end
    -- Base
    if baseFrame and baseFrame.glow then
        baseFrame.glow:SetVertexColor(color.r, color.g, color.b, 0.3)
    end
    -- Firefly
    if fireflyFrame and fireflyFrame.dot then
        fireflyFrame.dot:SetVertexColor(color.r, color.g, color.b, 0.9)
    end
    -- Chevrons
    local elevState = DXD.state.elevationState
    local elevColor = Config.COLORS.ELEV_LEVEL
    if elevState == "above" then
        elevColor = Config.COLORS.ELEV_ABOVE
    elseif elevState == "below" then
        elevColor = Config.COLORS.ELEV_BELOW
    end
    for _, cf in ipairs(chevronFrames) do
        cf.text:SetTextColor(elevColor.r, elevColor.g, elevColor.b, elevColor.a)
    end
end

------------------------------------------------------------------------
-- POSITIONING
------------------------------------------------------------------------

local function UpdateBeamPosition(screenX, screenY, distance)
    if not screenX or not screenY then
        if beamFrame then beamFrame:Hide() end
        if baseFrame then baseFrame:Hide() end
        if fireflyFrame then fireflyFrame:Hide() end
        return
    end

    local morphProgress = Anim:GetMorphProgress()
    local beamHeight = Anim:GetBeamHeight(distance)
    local beamWidth = Anim:GetBeamWidth(distance)
    local glowWidth = Anim:GetGlowWidth(distance)
    local pulseAlpha = Anim:GetPulseAlpha(distance)

    -- Apply idle fade
    local idleAlpha = Anim:GetIdleAlpha()
    local finalAlpha = pulseAlpha * idleAlpha

    -- Fade-in/out transition
    local fadeDelta = targetFadeAlpha - fadeAlpha
    if math.abs(fadeDelta) > 0.01 then
        local speed = fadeDelta > 0 and (1 / Config.ANIMATION.BEACON_FADE_IN) or (1 / Config.ANIMATION.BEACON_FADE_OUT)
        fadeAlpha = fadeAlpha + fadeDelta * math.min(1, speed * 0.05)
    else
        fadeAlpha = targetFadeAlpha
    end
    finalAlpha = finalAlpha * fadeAlpha

    -- Check for arrival animation
    local arrivalScale, arrivalAlpha, arrivalComplete = Anim:UpdateArrival()
    if Anim:IsArrivalPlaying() then
        finalAlpha = finalAlpha * arrivalAlpha
    end

    -- BEAM (far/medium range)
    if morphProgress < 0.95 and beamHeight > 0 then
        local beamAlpha = finalAlpha * (1 - morphProgress)

        beamFrame:ClearAllPoints()
        beamFrame:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", screenX, screenY)

        -- Shaft sizing
        beamFrame.shaft:SetSize(beamWidth, beamHeight)
        beamFrame.shaft:SetAlpha(beamAlpha)

        -- Glow sizing
        beamFrame.glow:SetSize(glowWidth, beamHeight)
        beamFrame.glow:SetAlpha(beamAlpha * 0.2)

        beamFrame.glow2:SetSize(glowWidth * 2, beamHeight)
        beamFrame.glow2:SetAlpha(beamAlpha * 0.08)

        beamFrame:SetSize(glowWidth * 2, beamHeight)
        beamFrame:Show()
    else
        beamFrame:Hide()
    end

    -- BASE GLOW
    if morphProgress < 0.8 then
        local baseSize = Utils.Remap(distance or 100, 30, 200, 16, 8)
        baseFrame:SetSize(baseSize, baseSize)
        baseFrame:ClearAllPoints()
        baseFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", screenX, screenY)
        baseFrame:SetAlpha(finalAlpha * 0.3 * (1 - morphProgress))
        baseFrame:Show()
    else
        baseFrame:Hide()
    end

    -- FIREFLY (close range)
    if morphProgress > 0.05 then
        local bobOffset = Anim:GetBobOffset()
        local fireflyAlpha = finalAlpha * morphProgress

        -- If significant elevation delta, stretch into arrow shape
        local elevDelta = DXD.state.elevationDelta
        local fireflySize = 10
        local fireflyHeight = 10
        if math.abs(elevDelta) > Config.ELEVATION.ABOVE_THRESHOLD then
            fireflyHeight = 16  -- Elongated
        end

        fireflyFrame:SetSize(fireflySize * arrivalScale, fireflyHeight * arrivalScale)
        fireflyFrame:ClearAllPoints()
        fireflyFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", screenX, screenY + bobOffset)
        fireflyFrame:SetAlpha(fireflyAlpha)
        fireflyFrame:Show()
    else
        fireflyFrame:Hide()
    end

    -- CHEVRONS on the beam (medium distance, elevation differs)
    UpdateChevrons(screenX, screenY, beamHeight, distance, finalAlpha, morphProgress)

    if arrivalComplete then
        Beacon:Hide()
        DXD:Debug("Arrival animation complete, beacon hidden")
    end
end

local function UpdateChevrons(screenX, screenY, beamHeight, distance, alpha, morphProgress)
    local elevState = DXD.state.elevationState
    local showChevrons = (elevState ~= "level")
        and distance and distance > Config.BEACON.CLOSE_DISTANCE
        and distance < Config.BEACON.FAR_DISTANCE
        and morphProgress < 0.5

    if not showChevrons then
        for _, cf in ipairs(chevronFrames) do
            cf:Hide()
        end
        return
    end

    local chevronChar = elevState == "above" and "\226\150\178" or "\226\150\188"  -- ▲ or ▼
    local chevOffset = Anim:GetChevronOffset()
    local spacing = beamHeight / (#chevronFrames + 1)

    for i, cf in ipairs(chevronFrames) do
        local yPos = screenY + spacing * i + chevOffset
        if yPos > screenY and yPos < screenY + beamHeight then
            cf.text:SetText(chevronChar)
            cf:ClearAllPoints()
            cf:SetPoint("CENTER", UIParent, "BOTTOMLEFT", screenX, yPos)
            cf:SetAlpha(alpha * 0.6)
            cf:Show()
        else
            cf:Hide()
        end
    end
end

------------------------------------------------------------------------
-- PUBLIC API
------------------------------------------------------------------------

function Beacon:Show()
    isVisible = true
    targetFadeAlpha = 1
    ApplyBeaconColor(DXD:GetBeaconColor())
end

function Beacon:Hide()
    isVisible = false
    targetFadeAlpha = 0
    if beamFrame then beamFrame:Hide() end
    if baseFrame then baseFrame:Hide() end
    if fireflyFrame then fireflyFrame:Hide() end
    for _, cf in ipairs(chevronFrames) do cf:Hide() end
end

function Beacon:TriggerArrival()
    Anim:TriggerArrival()
end

function Beacon:OnTargetChanged()
    self:Show()
    Anim:Reset()
    fadeAlpha = 0
    targetFadeAlpha = 1
    ApplyBeaconColor(DXD:GetBeaconColor())
end

function Beacon:OnTargetCleared()
    self:Hide()
    Anim:Reset()
end

------------------------------------------------------------------------
-- UPDATE
------------------------------------------------------------------------

function Beacon:OnUpdate(elapsed)
    if not isVisible then return end
    if not DXD.state.hasTarget then return end
    if not updateAccum then return end

    if not updateAccum:ShouldUpdate(elapsed) then return end

    local state = DXD.state

    -- Update animations
    Anim:UpdateMorph(state.distance3D, elapsed)
    Anim:UpdateIdleFade(state.playerMoving, elapsed)

    -- Project target world position to screen
    local targetX = state.targetWorldX
    local targetY = state.targetWorldY
    local targetZ = state.targetWorldZ or 0

    local screenX, screenY, onScreen = Utils.WorldToScreen(targetX, targetY, targetZ)

    if onScreen then
        UpdateBeamPosition(screenX, screenY, state.distance3D)
        ApplyBeaconColor(DXD:GetBeaconColor())
    else
        -- Target is behind camera or off screen
        if beamFrame then beamFrame:Hide() end
        if baseFrame then baseFrame:Hide() end
        if fireflyFrame then fireflyFrame:Hide() end
        for _, cf in ipairs(chevronFrames) do cf:Hide() end
    end
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function Beacon:Initialize()
    updateAccum = Utils.CreateAccumulator(Config.UPDATE_RATES.BEACON)
    CreateBeaconFrames()
    DXD:Debug("Beacon initialized")
end
