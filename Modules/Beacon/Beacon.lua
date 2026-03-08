------------------------------------------------------------------------
-- DestinationXD - Beacon.lua
-- The in-world waypoint beam - visual centerpiece
-- Inspired by WaypointUI's pillar beam with gradient, contextual icon,
-- and elevation indicators. Square icon base with masked beam reveal.
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
local baseFrame      -- Ground marker with objective icon (square, WaypointUI-style)
local fireflyFrame   -- Close-range floating point
local chevronFrames = {} -- Elevation chevrons on the beam
local elevBadge      -- Elevation badge on base icon (above/below/cave)

-- State
local isVisible = false
local currentColor = nil
local fadeAlpha = 0
local targetFadeAlpha = 0
local lastElapsed = 0.016
local beamMaskScale = 0  -- Masked reveal (0 = hidden, 1 = fully revealed)

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

-- Fallback to simple colored texture if atlas not available
local OBJECTIVE_FALLBACK_COLORS = {
    quest     = { r = 1.0, g = 0.84, b = 0.0 },
    waypoint  = { r = 0.4, g = 0.85, b = 1.0 },
    corpse    = { r = 0.9, g = 0.25, b = 0.25 },
    travel    = { r = 0.88, g = 0.88, b = 0.92 },
    tomtom    = { r = 1.0, g = 0.55, b = 0.0 },
    dungeon   = { r = 0.7, g = 0.45, b = 1.0 },
    flight    = { r = 0.27, g = 1.0, b = 0.53 },
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

    -- Gradient overlay to fade beam at the top
    beamFrame.gradient = beamFrame:CreateTexture(nil, "ARTWORK", nil, 3)
    beamFrame.gradient:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    beamFrame.gradient:SetBlendMode("MOD")
    beamFrame.gradient:SetPoint("BOTTOM")
    beamFrame.gradient:SetGradient("VERTICAL", CreateColor(1, 1, 1, 1), CreateColor(0, 0, 0, 0))

    -- Beam base glow (soft circle at the base of beam)
    beamFrame.baseGlow = beamFrame:CreateTexture(nil, "ARTWORK", nil, -1)
    beamFrame.baseGlow:SetTexture("Interface\\COMMON\\Indicator-Yellow")
    beamFrame.baseGlow:SetBlendMode("ADD")
    beamFrame.baseGlow:SetPoint("BOTTOM", 0, -6)
    beamFrame.baseGlow:SetSize(40, 12)
    beamFrame.baseGlow:SetAlpha(0.15)

    ----------------------------------------------------------------
    -- BASE MARKER: Square icon (WaypointUI-inspired)
    ----------------------------------------------------------------
    baseFrame = CreateFrame("Frame", "DXDBeaconBase", UIParent)
    baseFrame:SetFrameStrata("BACKGROUND")
    baseFrame:SetFrameLevel(5)
    baseFrame:SetSize(34, 34)
    baseFrame:Hide()

    -- Square background plate (dark, subtle)
    baseFrame.plate = baseFrame:CreateTexture(nil, "BACKGROUND")
    baseFrame.plate:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    baseFrame.plate:SetAllPoints()
    baseFrame.plate:SetVertexColor(0.03, 0.03, 0.06, 0.75)

    -- Border (1px colored edge)
    baseFrame.border = baseFrame:CreateTexture(nil, "ARTWORK", nil, -1)
    baseFrame.border:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    baseFrame.border:SetPoint("TOPLEFT", -1, 1)
    baseFrame.border:SetPoint("BOTTOMRIGHT", 1, -1)

    -- Inner glow (subtle color wash inside square)
    baseFrame.innerGlow = baseFrame:CreateTexture(nil, "ARTWORK", nil, 0)
    baseFrame.innerGlow:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    baseFrame.innerGlow:SetBlendMode("ADD")
    baseFrame.innerGlow:SetPoint("TOPLEFT", 1, -1)
    baseFrame.innerGlow:SetPoint("BOTTOMRIGHT", -1, 1)
    baseFrame.innerGlow:SetAlpha(0.08)

    -- Objective type icon (centered in square)
    baseFrame.icon = baseFrame:CreateTexture(nil, "OVERLAY", nil, 2)
    baseFrame.icon:SetSize(20, 20)
    baseFrame.icon:SetPoint("CENTER", 0, 0)
    baseFrame.icon:SetAlpha(0.9)

    -- Distance label below base
    baseFrame.distText = baseFrame:CreateFontString(nil, "OVERLAY")
    baseFrame.distText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    baseFrame.distText:SetShadowColor(0, 0, 0, 0.8)
    baseFrame.distText:SetShadowOffset(1, -1)
    baseFrame.distText:SetPoint("TOP", baseFrame, "BOTTOM", 0, -3)
    baseFrame.distText:SetJustifyH("CENTER")

    -- Target name label above base
    baseFrame.nameText = baseFrame:CreateFontString(nil, "OVERLAY")
    baseFrame.nameText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    baseFrame.nameText:SetShadowColor(0, 0, 0, 0.8)
    baseFrame.nameText:SetShadowOffset(1, -1)
    baseFrame.nameText:SetPoint("BOTTOM", baseFrame, "TOP", 0, 3)
    baseFrame.nameText:SetJustifyH("CENTER")
    baseFrame.nameText:SetWidth(150)
    baseFrame.nameText:SetWordWrap(false)

    ----------------------------------------------------------------
    -- ELEVATION BADGE (on top-right corner of base icon)
    ----------------------------------------------------------------
    elevBadge = CreateFrame("Frame", "DXDElevBadge", baseFrame)
    elevBadge:SetFrameStrata("BACKGROUND")
    elevBadge:SetFrameLevel(7)
    elevBadge:SetSize(16, 16)
    elevBadge:SetPoint("TOPLEFT", baseFrame, "TOPRIGHT", 2, 2)
    elevBadge:Hide()

    elevBadge.bg = elevBadge:CreateTexture(nil, "BACKGROUND")
    elevBadge.bg:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    elevBadge.bg:SetAllPoints()
    elevBadge.bg:SetVertexColor(0.03, 0.03, 0.06, 0.85)

    elevBadge.text = elevBadge:CreateFontString(nil, "OVERLAY")
    elevBadge.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    elevBadge.text:SetShadowColor(0, 0, 0, 0.8)
    elevBadge.text:SetShadowOffset(1, -1)
    elevBadge.text:SetPoint("CENTER")

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
    -- Base glow at bottom
    if beamFrame and beamFrame.baseGlow then
        beamFrame.baseGlow:SetVertexColor(color.r, color.g, color.b, 0.15)
    end

    -- Square base: border + inner glow
    if baseFrame then
        if baseFrame.border then
            baseFrame.border:SetVertexColor(color.r, color.g, color.b, 0.5)
        end
        if baseFrame.innerGlow then
            baseFrame.innerGlow:SetVertexColor(color.r, color.g, color.b, 0.08)
        end
        if baseFrame.distText then
            baseFrame.distText:SetTextColor(color.r, color.g, color.b, 0.7)
        end
        if baseFrame.nameText then
            baseFrame.nameText:SetTextColor(color.r, color.g, color.b, 0.5)
        end
    end

    -- Firefly
    if fireflyFrame and fireflyFrame.dot then
        fireflyFrame.dot:SetVertexColor(color.r, color.g, color.b, 0.9)
    end
    if fireflyFrame and fireflyFrame.ring then
        fireflyFrame.ring:SetVertexColor(color.r, color.g, color.b, 0.3)
    end

    -- Chevrons (use elevation colors)
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
            baseFrame.icon:SetTexCoord(0, 1, 0, 1)  -- Reset texcoord from any previous fallback
            baseFrame.icon:SetDesaturated(true)
            -- Tint the icon to match beacon color
            local color = DXD:GetBeaconColor()
            if color then
                baseFrame.icon:SetVertexColor(color.r, color.g, color.b, 0.9)
            end
            baseFrame.icon:Show()
        else
            -- Fallback: use a simple colored square indicator
            baseFrame.icon:SetTexture("Interface\\COMMON\\Indicator-Yellow")
            baseFrame.icon:SetTexCoord(0, 1, 0, 1)
            local fallback = OBJECTIVE_FALLBACK_COLORS[targetType]
            if fallback then
                baseFrame.icon:SetVertexColor(fallback.r, fallback.g, fallback.b, 0.9)
            end
            baseFrame.icon:Show()
        end
    else
        baseFrame.icon:SetTexture("Interface\\COMMON\\Indicator-Yellow")
        baseFrame.icon:SetTexCoord(0, 1, 0, 1)
        baseFrame.icon:Show()
    end
end

--- Update the elevation badge
local function UpdateElevationBadge(distance)
    if not elevBadge then return end
    local elevState = DXD.state.elevationState
    local vertDist = DXD.state.distanceVertical or 0

    -- Only show if there's meaningful vertical difference and we're not too close/far
    if elevState == "level" or not distance or distance < 5 or distance > 300 or vertDist < 5 then
        elevBadge:Hide()
        return
    end

    local elevColor, symbol
    if elevState == "above" then
        elevColor = Config.COLORS.ELEV_ABOVE
        symbol = "\226\150\178"  -- ▲
    elseif elevState == "below" then
        elevColor = Config.COLORS.ELEV_BELOW
        symbol = "\226\150\188"  -- ▼
    else
        elevBadge:Hide()
        return
    end

    elevBadge.text:SetText(symbol)
    elevBadge.text:SetTextColor(elevColor.r, elevColor.g, elevColor.b, 0.9)
    elevBadge:Show()
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

    -- Apply user settings
    local userOpacity = DXD.db and DXD.db.beamOpacity or 0.85
    local userScale = DXD.db and DXD.db.beaconScale or 1.2
    local widthScale = DXD.db and DXD.db.beamWidthScale or 1.5
    beamWidth = beamWidth * widthScale
    glowWidth = glowWidth * widthScale

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

    -- Masked beam reveal animation (scales from 0 to 1 on intro)
    if targetFadeAlpha > 0 then
        beamMaskScale = math.min(1, beamMaskScale + lastElapsed * 2.5)  -- ~0.4s to fully reveal
    else
        beamMaskScale = math.max(0, beamMaskScale - lastElapsed * 4)
    end

    -- Check for arrival animation
    local arrivalScale, arrivalAlpha, arrivalComplete = Anim:UpdateArrival()
    if Anim:IsArrivalPlaying() then
        finalAlpha = finalAlpha * arrivalAlpha
    end

    -- Apply masked reveal to beam height
    local revealedHeight = beamHeight * beamMaskScale

    -- BEAM (far/medium range)
    if morphProgress < 0.95 and revealedHeight > 2 then
        local beamAlpha = finalAlpha * (1 - morphProgress)

        beamFrame:ClearAllPoints()
        beamFrame:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", screenX, screenY)

        -- Core shaft (bright, thin)
        beamFrame.shaft:SetSize(beamWidth, revealedHeight)
        beamFrame.shaft:SetAlpha(beamAlpha)

        -- Inner glow (wider, softer)
        beamFrame.glow:SetSize(glowWidth, revealedHeight)
        beamFrame.glow:SetAlpha(beamAlpha * 0.30)

        -- Outer glow (widest, very soft)
        beamFrame.glow2:SetSize(glowWidth * 2.5, revealedHeight)
        beamFrame.glow2:SetAlpha(beamAlpha * 0.12)

        -- Gradient overlay
        beamFrame.gradient:SetSize(glowWidth * 2.5, revealedHeight)
        beamFrame.gradient:SetAlpha(1)

        -- Base glow at bottom of beam
        beamFrame.baseGlow:SetAlpha(beamAlpha * 0.2)

        beamFrame:SetSize(glowWidth * 2.5, revealedHeight)
        beamFrame:Show()
    else
        beamFrame:Hide()
    end

    -- BASE MARKER (square icon - always visible when beam is showing)
    if morphProgress < 0.8 then
        -- Distance-based scaling (closer = larger icon), scaled by user preference
        local baseSize = Utils.Remap(distance or 100, 10, 200, 38, 24) * userScale
        baseFrame:SetSize(baseSize, baseSize)

        -- Icon scales with base
        local iconSize = baseSize * 0.60
        baseFrame.icon:SetSize(iconSize, iconSize)

        -- Border extends 1px beyond
        baseFrame.border:ClearAllPoints()
        baseFrame.border:SetPoint("TOPLEFT", -1, 1)
        baseFrame.border:SetPoint("BOTTOMRIGHT", 1, -1)

        baseFrame:ClearAllPoints()
        baseFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", screenX, screenY)
        baseFrame:SetAlpha(finalAlpha * 0.9 * (1 - morphProgress))

        -- Show distance at base
        if distance and baseFrame.distText then
            baseFrame.distText:SetText(Utils.FormatDistance(distance))
        end

        -- Show target name (if enabled)
        if DXD.db and DXD.db.showBeaconName ~= false then
            local targetName = DXD.state.targetName
            if targetName and baseFrame.nameText then
                if #targetName > 25 then
                    targetName = string.sub(targetName, 1, 22) .. "..."
                end
                baseFrame.nameText:SetText(targetName)
                baseFrame.nameText:Show()
            end
        elseif baseFrame.nameText then
            baseFrame.nameText:Hide()
        end

        -- Update elevation badge
        UpdateElevationBadge(distance)

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
    UpdateChevrons(screenX, screenY, revealedHeight, distance, finalAlpha, morphProgress)

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
    beamMaskScale = 0
    if beamFrame then beamFrame:Hide() end
    if baseFrame then baseFrame:Hide() end
    if fireflyFrame then fireflyFrame:Hide() end
    if elevBadge then elevBadge:Hide() end
    for _, cf in ipairs(chevronFrames) do cf:Hide() end
end

function Beacon:TriggerArrival()
    Anim:TriggerArrival()
end

function Beacon:OnTargetChanged()
    self:Show()
    Anim:Reset()
    fadeAlpha = 0
    beamMaskScale = 0  -- Reset masked reveal for fresh intro animation
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
        if isClamped and not DXD.db.showThroughTerrain then
            local savedAlpha = fadeAlpha
            fadeAlpha = fadeAlpha * 0.35
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
        if elevBadge then elevBadge:Hide() end
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
