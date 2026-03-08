------------------------------------------------------------------------
-- DestinationXD - Beacon.lua
-- The in-world waypoint beam - the visual centerpiece
-- Inspired by WaypointUI's pillar beam with gradient, base icon, and
-- animated FX - but with our own moonlight aesthetic
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local Beacon = {}
DXD:RegisterModule("Beacon", Beacon)

local Utils = DXD.Utils
local Config = DXD.Config
local Pool = DXD:GetModule("BeaconPool")
local Anim = DXD:GetModule("BeaconAnimations")

-- Beacon visual frames
local beamFrame      -- The main beam shaft
local baseFrame      -- Ground marker with objective icon
local fireflyFrame   -- Close-range floating point
local chevronFrames = {} -- Elevation chevrons on the beam

-- State
local isVisible = false
local currentColor = nil
local fadeAlpha = 0
local targetFadeAlpha = 0
local lastElapsed = 0.016

-- Objective type icon mapping (WoW built-in atlas names)
local OBJECTIVE_ICONS = {
    quest     = "QuestNormal",
    waypoint  = "Waypoint-MapPin-ChatIcon",
    corpse    = "poi-graveyard-neutral",
    travel    = "FlightMaster",
    tomtom    = "Waypoint-MapPin-ChatIcon",
    dungeon   = "Dungeon",
    flight    = "FlightMaster",
}

------------------------------------------------------------------------
-- FRAME CREATION
------------------------------------------------------------------------

local function CreateBeaconFrames()
    -- Main beam container
    beamFrame = CreateFrame("Frame", "DXDBeaconBeam", UIParent)
    beamFrame:SetFrameStrata("BACKGROUND")
    beamFrame:SetFrameLevel(1)
    beamFrame:Hide()

    -- Beam core (bright center line)
    beamFrame.shaft = beamFrame:CreateTexture(nil, "ARTWORK", nil, 2)
    beamFrame.shaft:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    beamFrame.shaft:SetBlendMode("ADD")
    beamFrame.shaft:SetPoint("BOTTOM")

    -- Inner glow (medium width, moderate alpha)
    beamFrame.glow = beamFrame:CreateTexture(nil, "ARTWORK", nil, 1)
    beamFrame.glow:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    beamFrame.glow:SetBlendMode("ADD")
    beamFrame.glow:SetPoint("BOTTOM")

    -- Outer glow (wide, soft)
    beamFrame.glow2 = beamFrame:CreateTexture(nil, "ARTWORK", nil, 0)
    beamFrame.glow2:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    beamFrame.glow2:SetBlendMode("ADD")
    beamFrame.glow2:SetPoint("BOTTOM")

    -- Gradient overlay to fade beam at the top (transparent at top, opaque at bottom)
    beamFrame.gradient = beamFrame:CreateTexture(nil, "ARTWORK", nil, 3)
    beamFrame.gradient:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    beamFrame.gradient:SetBlendMode("MOD")
    beamFrame.gradient:SetPoint("BOTTOM")
    beamFrame.gradient:SetGradient("VERTICAL", CreateColor(1, 1, 1, 1), CreateColor(0, 0, 0, 0))

    -- Base ground marker (larger, more visible)
    baseFrame = CreateFrame("Frame", "DXDBeaconBase", UIParent)
    baseFrame:SetFrameStrata("BACKGROUND")
    baseFrame:SetFrameLevel(5)
    baseFrame:SetSize(28, 28)
    baseFrame:Hide()

    -- Base outer ring glow
    baseFrame.ring = baseFrame:CreateTexture(nil, "ARTWORK", nil, 0)
    baseFrame.ring:SetTexture("Interface\\COMMON\\RingBorder")
    baseFrame.ring:SetBlendMode("ADD")
    baseFrame.ring:SetAllPoints()

    -- Base fill glow (center dot)
    baseFrame.glow = baseFrame:CreateTexture(nil, "ARTWORK", nil, 1)
    baseFrame.glow:SetTexture("Interface\\COMMON\\Indicator-Yellow")
    baseFrame.glow:SetBlendMode("ADD")
    baseFrame.glow:SetSize(14, 14)
    baseFrame.glow:SetPoint("CENTER")

    -- Objective type icon
    baseFrame.icon = baseFrame:CreateTexture(nil, "OVERLAY", nil, 2)
    baseFrame.icon:SetSize(16, 16)
    baseFrame.icon:SetPoint("CENTER", 0, 0)
    baseFrame.icon:SetBlendMode("ADD")
    baseFrame.icon:SetAlpha(0.9)

    -- Distance label at base
    baseFrame.distText = baseFrame:CreateFontString(nil, "OVERLAY")
    baseFrame.distText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    baseFrame.distText:SetShadowColor(0, 0, 0, 0.8)
    baseFrame.distText:SetShadowOffset(1, -1)
    baseFrame.distText:SetPoint("TOP", baseFrame, "BOTTOM", 0, -2)
    baseFrame.distText:SetJustifyH("CENTER")

    -- Firefly point (close range)
    fireflyFrame = CreateFrame("Frame", "DXDBeaconFirefly", UIParent)
    fireflyFrame:SetFrameStrata("BACKGROUND")
    fireflyFrame:SetFrameLevel(4)
    fireflyFrame:SetSize(12, 12)
    fireflyFrame:Hide()

    fireflyFrame.dot = fireflyFrame:CreateTexture(nil, "ARTWORK")
    fireflyFrame.dot:SetTexture("Interface\\COMMON\\Indicator-Yellow")
    fireflyFrame.dot:SetBlendMode("ADD")
    fireflyFrame.dot:SetAllPoints()

    fireflyFrame.ring = fireflyFrame:CreateTexture(nil, "ARTWORK", nil, -1)
    fireflyFrame.ring:SetTexture("Interface\\COMMON\\RingBorder")
    fireflyFrame.ring:SetBlendMode("ADD")
    fireflyFrame.ring:SetSize(20, 20)
    fireflyFrame.ring:SetPoint("CENTER")
    fireflyFrame.ring:SetAlpha(0.3)

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

    -- Beam shaft (bright core)
    if beamFrame and beamFrame.shaft then
        beamFrame.shaft:SetVertexColor(color.r, color.g, color.b, color.a or 0.85)
    end
    -- Inner glow
    if beamFrame and beamFrame.glow then
        beamFrame.glow:SetVertexColor(color.r, color.g, color.b, 0.25)
    end
    -- Outer glow
    if beamFrame and beamFrame.glow2 then
        beamFrame.glow2:SetVertexColor(color.r, color.g, color.b, 0.10)
    end
    -- Base ring
    if baseFrame and baseFrame.ring then
        baseFrame.ring:SetVertexColor(color.r, color.g, color.b, 0.5)
    end
    -- Base center glow
    if baseFrame and baseFrame.glow then
        baseFrame.glow:SetVertexColor(color.r, color.g, color.b, 0.6)
    end
    -- Base icon
    if baseFrame and baseFrame.icon then
        baseFrame.icon:SetVertexColor(color.r, color.g, color.b, 0.9)
    end
    -- Base distance text
    if baseFrame and baseFrame.distText then
        baseFrame.distText:SetTextColor(color.r, color.g, color.b, 0.7)
    end
    -- Firefly
    if fireflyFrame and fireflyFrame.dot then
        fireflyFrame.dot:SetVertexColor(color.r, color.g, color.b, 0.9)
    end
    if fireflyFrame and fireflyFrame.ring then
        fireflyFrame.ring:SetVertexColor(color.r, color.g, color.b, 0.3)
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

--- Update the base objective icon based on target type
local function UpdateBaseIcon()
    if not baseFrame or not baseFrame.icon then return end
    local targetType = DXD.state.targetType or "waypoint"
    local atlas = OBJECTIVE_ICONS[targetType]

    if atlas then
        local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
        if info then
            baseFrame.icon:SetAtlas(atlas)
            baseFrame.icon:Show()
        else
            -- Fallback: use a simple dot for unknown atlas
            baseFrame.icon:SetTexture("Interface\\COMMON\\Indicator-Yellow")
            baseFrame.icon:Show()
        end
    else
        baseFrame.icon:SetTexture("Interface\\COMMON\\Indicator-Yellow")
        baseFrame.icon:Show()
    end
end

------------------------------------------------------------------------
-- POSITIONING
------------------------------------------------------------------------

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

local function UpdateBeamPosition(screenX, screenY, distance)
    if not screenX or not screenY then
        if beamFrame then beamFrame:Hide() end
        if baseFrame then baseFrame:Hide() end
        if fireflyFrame then fireflyFrame:Hide() end
        return
    end

    local morphProgress = Anim:GetMorphProgress()
    local beamHeight = Anim:GetBeamHeight(distance, screenY)
    local beamWidth = Anim:GetBeamWidth(distance)
    local glowWidth = Anim:GetGlowWidth(distance)
    local pulseAlpha = Anim:GetPulseAlpha(distance)

    -- Apply user opacity setting
    local userOpacity = DXD.db and DXD.db.beamOpacity or 0.80

    -- Apply idle fade (minimum 0.35 so beam is always visible when active)
    local idleAlpha = Anim:GetIdleAlpha()
    idleAlpha = math.max(0.35, idleAlpha)
    local finalAlpha = pulseAlpha * idleAlpha * userOpacity

    -- Gentle distance dimming (only beyond 150y, down to 50%)
    local distDim = 1
    if distance and distance > 150 then
        distDim = Utils.Remap(distance, 150, 400, 1.0, 0.50)
    end
    finalAlpha = finalAlpha * distDim

    -- Fade-in/out transition
    local fadeDelta = targetFadeAlpha - fadeAlpha
    if math.abs(fadeDelta) > 0.01 then
        local speed = fadeDelta > 0 and (1 / Config.ANIMATION.BEACON_FADE_IN) or (1 / Config.ANIMATION.BEACON_FADE_OUT)
        fadeAlpha = fadeAlpha + fadeDelta * math.min(1, speed * lastElapsed)
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

        -- Core shaft (bright, thin)
        beamFrame.shaft:SetSize(beamWidth, beamHeight)
        beamFrame.shaft:SetAlpha(beamAlpha)

        -- Inner glow (wider, softer)
        beamFrame.glow:SetSize(glowWidth, beamHeight)
        beamFrame.glow:SetAlpha(beamAlpha * 0.30)

        -- Outer glow (widest, very soft)
        beamFrame.glow2:SetSize(glowWidth * 2.5, beamHeight)
        beamFrame.glow2:SetAlpha(beamAlpha * 0.12)

        -- Gradient overlay (fade to transparent at top)
        beamFrame.gradient:SetSize(glowWidth * 2.5, beamHeight)
        beamFrame.gradient:SetAlpha(1)

        beamFrame:SetSize(glowWidth * 2.5, beamHeight)
        beamFrame:Show()
    else
        beamFrame:Hide()
    end

    -- BASE MARKER (always visible when beam is showing)
    if morphProgress < 0.8 then
        local baseSize = Utils.Remap(distance or 100, 10, 200, 32, 18)
        baseFrame:SetSize(baseSize, baseSize)
        baseFrame.glow:SetSize(baseSize * 0.5, baseSize * 0.5)
        baseFrame.icon:SetSize(baseSize * 0.55, baseSize * 0.55)
        baseFrame:ClearAllPoints()
        baseFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", screenX, screenY)
        baseFrame:SetAlpha(finalAlpha * 0.8 * (1 - morphProgress))

        -- Show distance at base
        if distance and baseFrame.distText then
            baseFrame.distText:SetText(Utils.FormatDistance(distance))
        end

        baseFrame:Show()
    else
        baseFrame:Hide()
    end

    -- FIREFLY (close range)
    if morphProgress > 0.05 then
        local bobOffset = Anim:GetBobOffset()
        local fireflyAlpha = finalAlpha * morphProgress

        local elevDelta = DXD.state.elevationDelta
        local fireflySize = 12
        local fireflyHeight = 12
        if math.abs(elevDelta) > Config.ELEVATION.ABOVE_THRESHOLD then
            fireflyHeight = 18
        end

        fireflyFrame:SetSize(fireflySize * arrivalScale, fireflyHeight * arrivalScale)
        fireflyFrame.ring:SetSize(fireflySize * 1.8 * arrivalScale, fireflyHeight * 1.8 * arrivalScale)
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

------------------------------------------------------------------------
-- PUBLIC API
------------------------------------------------------------------------

function Beacon:Show()
    isVisible = true
    targetFadeAlpha = 1
    ApplyBeaconColor(DXD:GetBeaconColor())
    UpdateBaseIcon()
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
    UpdateBaseIcon()
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

    -- No throttling - run every frame for smooth visuals
    lastElapsed = elapsed

    local state = DXD.state

    -- Update animations
    Anim:UpdateMorph(state.distance3D, elapsed)
    Anim:UpdateIdleFade(state.playerMoving, elapsed)

    -- Project target world position to screen
    local targetX = state.targetWorldX
    local targetY = state.targetWorldY
    local targetZ = state.targetWorldZ or 0

    local screenX, screenY, onScreen = Utils.WorldToScreen(targetX, targetY, targetZ)

    -- When showThroughTerrain is false and target is clamped, show beam
    -- at reduced opacity (dimmed) instead of hiding completely
    local isClamped = false
    if C_Navigation and C_Navigation.WasClampedToScreen then
        isClamped = C_Navigation.WasClampedToScreen()
    end

    if onScreen then
        -- If clamped and showThroughTerrain is false, dim the beam
        if isClamped and not DXD.db.showThroughTerrain then
            local savedAlpha = fadeAlpha
            fadeAlpha = fadeAlpha * 0.35  -- significantly dimmed
            UpdateBeamPosition(screenX, screenY, state.distance3D)
            fadeAlpha = savedAlpha
        else
            UpdateBeamPosition(screenX, screenY, state.distance3D)
        end
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
    CreateBeaconFrames()
    DXD:Debug("Beacon initialized")
end
