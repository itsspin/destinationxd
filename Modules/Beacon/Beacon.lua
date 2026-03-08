------------------------------------------------------------------------
-- DestinationXD - Beacon.lua
-- In-world waypoint beam with diamond base icon and edge indicator
-- Inspired by WaypointUI: thin elegant beam, diamond base, off-screen
-- edge indicator that moves along screen border
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local Beacon = {}
DXD:RegisterModule("Beacon", Beacon)

local Utils = DXD.Utils
local Config = DXD.Config
local Pool = DXD:GetModule("BeaconPool")
local Anim = DXD:GetModule("BeaconAnimations")

-- Lua refs
local math_sin = math.sin
local math_cos = math.cos
local math_atan2 = math.atan2
local math_abs = math.abs
local math_min = math.min
local math_max = math.max
local math_sqrt = math.sqrt
local math_rad = math.rad
local math_pi = math.pi

-- Visual frames
local beamFrame       -- Thin beam shaft + glow layers
local baseFrame       -- Diamond icon at beam base
local edgeFrame       -- Off-screen edge indicator (diamond + arrow)
local fireflyFrame    -- Close-range floating point
local elevBadge       -- Elevation badge on base icon
local chevronFrames = {}

-- State
local isVisible = false
local currentColor = nil
local fadeAlpha = 0
local targetFadeAlpha = 0
local lastElapsed = 0.016
local beamMaskScale = 0
local edgeSmoothedX, edgeSmoothedY = 0, 0
local lastOnScreen = true

-- Objective type icon mapping
local OBJECTIVE_ICONS = {
    quest     = "QuestNormal",
    waypoint  = "Waypoint-MapPin-ChatIcon",
    corpse    = "poi-graveyard-neutral",
    travel    = "FlightMaster",
    tomtom    = "Waypoint-MapPin-ChatIcon",
    dungeon   = "Dungeon",
    flight    = "FlightMaster",
}

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

local function CreateBeamFrame()
    beamFrame = CreateFrame("Frame", "DXDBeaconBeam", UIParent)
    beamFrame:SetFrameStrata("BACKGROUND")
    beamFrame:SetFrameLevel(1)
    beamFrame:Hide()

    -- Core shaft: very thin bright center line
    beamFrame.shaft = beamFrame:CreateTexture(nil, "ARTWORK", nil, 2)
    beamFrame.shaft:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    beamFrame.shaft:SetBlendMode("ADD")
    beamFrame.shaft:SetPoint("BOTTOM")

    -- Inner glow: slightly wider, low alpha
    beamFrame.glow = beamFrame:CreateTexture(nil, "ARTWORK", nil, 1)
    beamFrame.glow:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    beamFrame.glow:SetBlendMode("ADD")
    beamFrame.glow:SetPoint("BOTTOM")

    -- Outer glow: widest, very faint
    beamFrame.glow2 = beamFrame:CreateTexture(nil, "ARTWORK", nil, 0)
    beamFrame.glow2:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    beamFrame.glow2:SetBlendMode("ADD")
    beamFrame.glow2:SetPoint("BOTTOM")

    -- Gradient overlay: fades beam at top (MOD blend = multiply)
    beamFrame.gradient = beamFrame:CreateTexture(nil, "ARTWORK", nil, 3)
    beamFrame.gradient:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    beamFrame.gradient:SetBlendMode("MOD")
    beamFrame.gradient:SetPoint("BOTTOM")
    local ok = pcall(function()
        beamFrame.gradient:SetGradient("VERTICAL", CreateColor(1, 1, 1, 1), CreateColor(0, 0, 0, 0))
    end)
    if not ok then
        pcall(function()
            beamFrame.gradient:SetGradientAlpha("VERTICAL", 1, 1, 1, 1, 0, 0, 0, 0)
        end)
    end

    -- Soft glow at beam base (circular indicator texture for soft falloff)
    beamFrame.baseGlow = beamFrame:CreateTexture(nil, "ARTWORK", nil, -1)
    beamFrame.baseGlow:SetTexture("Interface\\COMMON\\Indicator-Yellow")
    beamFrame.baseGlow:SetBlendMode("ADD")
    beamFrame.baseGlow:SetPoint("BOTTOM", 0, -4)
    beamFrame.baseGlow:SetSize(28, 8)
    beamFrame.baseGlow:SetAlpha(0.12)
end

local function CreateBaseFrame()
    -- Diamond base icon (WaypointUI-style rotated square)
    baseFrame = CreateFrame("Frame", "DXDBeaconBase", UIParent)
    baseFrame:SetFrameStrata("BACKGROUND")
    baseFrame:SetFrameLevel(5)
    baseFrame:SetSize(32, 32)
    baseFrame:Hide()

    -- Diamond background plate (rotated 45 degrees)
    baseFrame.plate = baseFrame:CreateTexture(nil, "BACKGROUND")
    baseFrame.plate:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    baseFrame.plate:SetSize(18, 18)
    baseFrame.plate:SetPoint("CENTER")
    baseFrame.plate:SetRotation(math_rad(45))
    baseFrame.plate:SetVertexColor(0.04, 0.04, 0.08, 0.82)

    -- Diamond border (slightly larger rotated square behind the plate)
    baseFrame.border = baseFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
    baseFrame.border:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    baseFrame.border:SetSize(20, 20)
    baseFrame.border:SetPoint("CENTER")
    baseFrame.border:SetRotation(math_rad(45))

    -- Inner subtle color wash
    baseFrame.innerGlow = baseFrame:CreateTexture(nil, "ARTWORK", nil, 0)
    baseFrame.innerGlow:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    baseFrame.innerGlow:SetBlendMode("ADD")
    baseFrame.innerGlow:SetSize(16, 16)
    baseFrame.innerGlow:SetPoint("CENTER")
    baseFrame.innerGlow:SetRotation(math_rad(45))
    baseFrame.innerGlow:SetAlpha(0.06)

    -- Objective icon (centered, no rotation)
    baseFrame.icon = baseFrame:CreateTexture(nil, "OVERLAY", nil, 2)
    baseFrame.icon:SetSize(14, 14)
    baseFrame.icon:SetPoint("CENTER", 0, 0)
    baseFrame.icon:SetAlpha(0.85)

    -- Target name text above diamond
    baseFrame.nameText = baseFrame:CreateFontString(nil, "OVERLAY")
    baseFrame.nameText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    baseFrame.nameText:SetShadowColor(0, 0, 0, 0.8)
    baseFrame.nameText:SetShadowOffset(1, -1)
    baseFrame.nameText:SetPoint("BOTTOM", baseFrame, "TOP", 0, 4)
    baseFrame.nameText:SetJustifyH("CENTER")
    baseFrame.nameText:SetWidth(180)
    baseFrame.nameText:SetWordWrap(false)

    -- Distance text below diamond
    baseFrame.distText = baseFrame:CreateFontString(nil, "OVERLAY")
    baseFrame.distText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    baseFrame.distText:SetShadowColor(0, 0, 0, 0.8)
    baseFrame.distText:SetShadowOffset(1, -1)
    baseFrame.distText:SetPoint("TOP", baseFrame, "BOTTOM", 0, -2)
    baseFrame.distText:SetJustifyH("CENTER")
end

local function CreateEdgeIndicator()
    -- Off-screen diamond indicator with directional arrow
    edgeFrame = CreateFrame("Frame", "DXDEdgeIndicator", UIParent)
    edgeFrame:SetFrameStrata("HIGH")
    edgeFrame:SetFrameLevel(20)
    edgeFrame:SetSize(36, 36)
    edgeFrame:Hide()

    -- Diamond background (rotated square)
    edgeFrame.diamond = edgeFrame:CreateTexture(nil, "BACKGROUND")
    edgeFrame.diamond:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    edgeFrame.diamond:SetSize(16, 16)
    edgeFrame.diamond:SetPoint("CENTER")
    edgeFrame.diamond:SetRotation(math_rad(45))
    edgeFrame.diamond:SetVertexColor(0.05, 0.05, 0.10, 0.85)

    -- Diamond border
    edgeFrame.border = edgeFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
    edgeFrame.border:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    edgeFrame.border:SetSize(18, 18)
    edgeFrame.border:SetPoint("CENTER")
    edgeFrame.border:SetRotation(math_rad(45))

    -- Objective icon inside diamond
    edgeFrame.icon = edgeFrame:CreateTexture(nil, "OVERLAY", nil, 2)
    edgeFrame.icon:SetSize(11, 11)
    edgeFrame.icon:SetPoint("CENTER", 0, 0)
    edgeFrame.icon:SetAlpha(0.85)

    -- Directional arrow (shows which way to look)
    edgeFrame.arrow = edgeFrame:CreateTexture(nil, "ARTWORK", nil, 1)
    edgeFrame.arrow:SetTexture("Interface\\MINIMAP\\ROTATING-MINIMAPGROUPARROW")
    edgeFrame.arrow:SetSize(12, 12)
    edgeFrame.arrow:SetPoint("CENTER")
    edgeFrame.arrow:SetBlendMode("ADD")
    edgeFrame.arrow:SetAlpha(0.7)

    -- Distance text below
    edgeFrame.distText = edgeFrame:CreateFontString(nil, "OVERLAY")
    edgeFrame.distText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    edgeFrame.distText:SetShadowColor(0, 0, 0, 0.8)
    edgeFrame.distText:SetShadowOffset(1, -1)
    edgeFrame.distText:SetPoint("TOP", edgeFrame, "BOTTOM", 0, -1)
    edgeFrame.distText:SetJustifyH("CENTER")
end

local function CreateFireflyFrame()
    fireflyFrame = CreateFrame("Frame", "DXDBeaconFirefly", UIParent)
    fireflyFrame:SetFrameStrata("BACKGROUND")
    fireflyFrame:SetFrameLevel(4)
    fireflyFrame:SetSize(10, 10)
    fireflyFrame:Hide()

    fireflyFrame.dot = fireflyFrame:CreateTexture(nil, "ARTWORK")
    fireflyFrame.dot:SetTexture("Interface\\COMMON\\Indicator-Yellow")
    fireflyFrame.dot:SetBlendMode("ADD")
    fireflyFrame.dot:SetAllPoints()

    fireflyFrame.ring = fireflyFrame:CreateTexture(nil, "ARTWORK", nil, -1)
    fireflyFrame.ring:SetTexture("Interface\\COMMON\\RingBorder")
    fireflyFrame.ring:SetBlendMode("ADD")
    fireflyFrame.ring:SetSize(18, 18)
    fireflyFrame.ring:SetPoint("CENTER")
    fireflyFrame.ring:SetAlpha(0.25)
end

local function CreateElevationBadge()
    elevBadge = CreateFrame("Frame", "DXDElevBadge", baseFrame)
    elevBadge:SetFrameStrata("BACKGROUND")
    elevBadge:SetFrameLevel(7)
    elevBadge:SetSize(14, 14)
    elevBadge:SetPoint("TOPLEFT", baseFrame, "TOPRIGHT", 2, 2)
    elevBadge:Hide()

    elevBadge.bg = elevBadge:CreateTexture(nil, "BACKGROUND")
    elevBadge.bg:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    elevBadge.bg:SetAllPoints()
    elevBadge.bg:SetVertexColor(0.03, 0.03, 0.06, 0.85)

    elevBadge.text = elevBadge:CreateFontString(nil, "OVERLAY")
    elevBadge.text:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    elevBadge.text:SetShadowColor(0, 0, 0, 0.8)
    elevBadge.text:SetShadowOffset(1, -1)
    elevBadge.text:SetPoint("CENTER")
end

local function CreateChevronFrames()
    for i = 1, 5 do
        local cf = CreateFrame("Frame", "DXDChevron" .. i, UIParent)
        cf:SetFrameStrata("BACKGROUND")
        cf:SetFrameLevel(3)
        cf:SetSize(10, 10)
        cf:Hide()

        cf.text = cf:CreateFontString(nil, "OVERLAY")
        cf.text:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
        cf.text:SetPoint("CENTER")
        cf.text:SetShadowColor(0, 0, 0, 0.5)
        cf.text:SetShadowOffset(1, -1)
        chevronFrames[i] = cf
    end
end

local function CreateBeaconFrames()
    CreateBeamFrame()
    CreateBaseFrame()
    CreateEdgeIndicator()
    CreateFireflyFrame()
    CreateElevationBadge()
    CreateChevronFrames()
end

------------------------------------------------------------------------
-- COLOR APPLICATION
------------------------------------------------------------------------

local function ApplyBeaconColor(color)
    if not color then return end
    currentColor = color

    -- Beam layers
    if beamFrame then
        if beamFrame.shaft then beamFrame.shaft:SetVertexColor(color.r, color.g, color.b, 1) end
        if beamFrame.glow then beamFrame.glow:SetVertexColor(color.r, color.g, color.b, 1) end
        if beamFrame.glow2 then beamFrame.glow2:SetVertexColor(color.r, color.g, color.b, 1) end
        if beamFrame.baseGlow then beamFrame.baseGlow:SetVertexColor(color.r, color.g, color.b, 1) end
    end

    -- Diamond base
    if baseFrame then
        if baseFrame.border then baseFrame.border:SetVertexColor(color.r, color.g, color.b, 0.55) end
        if baseFrame.innerGlow then baseFrame.innerGlow:SetVertexColor(color.r, color.g, color.b, 0.06) end
        if baseFrame.distText then baseFrame.distText:SetTextColor(color.r * 0.9 + 0.1, color.g * 0.9 + 0.1, color.b * 0.9 + 0.1, 0.8) end
        if baseFrame.nameText then baseFrame.nameText:SetTextColor(color.r * 0.7 + 0.3, color.g * 0.7 + 0.3, color.b * 0.7 + 0.3, 0.6) end
    end

    -- Edge indicator
    if edgeFrame then
        if edgeFrame.border then edgeFrame.border:SetVertexColor(color.r, color.g, color.b, 0.6) end
        if edgeFrame.arrow then edgeFrame.arrow:SetVertexColor(color.r, color.g, color.b, 0.7) end
        if edgeFrame.distText then edgeFrame.distText:SetTextColor(color.r * 0.9 + 0.1, color.g * 0.9 + 0.1, color.b * 0.9 + 0.1, 0.7) end
    end

    -- Firefly
    if fireflyFrame then
        if fireflyFrame.dot then fireflyFrame.dot:SetVertexColor(color.r, color.g, color.b, 0.9) end
        if fireflyFrame.ring then fireflyFrame.ring:SetVertexColor(color.r, color.g, color.b, 0.25) end
    end

    -- Chevrons
    local elevState = DXD.state.elevationState
    local elevColor = Config.COLORS.ELEV_LEVEL
    if elevState == "above" then elevColor = Config.COLORS.ELEV_ABOVE
    elseif elevState == "below" then elevColor = Config.COLORS.ELEV_BELOW end
    for _, cf in ipairs(chevronFrames) do
        cf.text:SetTextColor(elevColor.r, elevColor.g, elevColor.b, elevColor.a)
    end
end

------------------------------------------------------------------------
-- ICON UPDATES
------------------------------------------------------------------------

local function SetObjectiveIcon(iconTexture, targetType)
    if not iconTexture then return end
    local atlas = OBJECTIVE_ICONS[targetType or "waypoint"]

    if atlas then
        local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
        if info then
            iconTexture:SetAtlas(atlas)
            iconTexture:SetTexCoord(0, 1, 0, 1)
            iconTexture:SetDesaturated(true)
            local color = DXD:GetBeaconColor()
            if color then
                iconTexture:SetVertexColor(color.r, color.g, color.b, 0.9)
            end
            iconTexture:Show()
            return
        end
    end

    -- Fallback: colored indicator
    iconTexture:SetTexture("Interface\\COMMON\\Indicator-Yellow")
    iconTexture:SetTexCoord(0, 1, 0, 1)
    local fallback = OBJECTIVE_FALLBACK_COLORS[targetType or "waypoint"]
    if fallback then
        iconTexture:SetVertexColor(fallback.r, fallback.g, fallback.b, 0.9)
    end
    iconTexture:Show()
end

local function UpdateBaseIcon()
    if not baseFrame or not baseFrame.icon then return end
    local targetType = DXD.state.targetType or "waypoint"
    SetObjectiveIcon(baseFrame.icon, targetType)
end

local function UpdateEdgeIcon()
    if not edgeFrame or not edgeFrame.icon then return end
    local targetType = DXD.state.targetType or "waypoint"
    SetObjectiveIcon(edgeFrame.icon, targetType)
end

------------------------------------------------------------------------
-- ELEVATION BADGE
------------------------------------------------------------------------

local function UpdateElevationBadge(distance)
    if not elevBadge then return end
    local elevState = DXD.state.elevationState
    local vertDist = DXD.state.distanceVertical or 0

    if elevState == "level" or not distance or distance < 5 or distance > 300 or vertDist < 5 then
        elevBadge:Hide()
        return
    end

    local elevColor, symbol
    if elevState == "above" then
        elevColor = Config.COLORS.ELEV_ABOVE
        symbol = "\226\150\178"  -- upward triangle
    elseif elevState == "below" then
        elevColor = Config.COLORS.ELEV_BELOW
        symbol = "\226\150\188"  -- downward triangle
    else
        elevBadge:Hide()
        return
    end

    elevBadge.text:SetText(symbol)
    elevBadge.text:SetTextColor(elevColor.r, elevColor.g, elevColor.b, 0.9)
    elevBadge:Show()
end

------------------------------------------------------------------------
-- SCREEN POSITION CALCULATION
------------------------------------------------------------------------

--- Get target screen position with support for off-screen cases
-- Returns: screenX, screenY, onScreen, relBearing
local function GetTargetScreenInfo(state)
    -- Method 1: C_Navigation (supertracked waypoints)
    if C_Navigation and C_Navigation.HasValidScreenPosition and C_Navigation.HasValidScreenPosition() then
        local navFrame = C_Navigation.GetFrame()
        if navFrame and navFrame:IsShown() then
            local cx, cy = navFrame:GetCenter()
            if cx and cy then
                local clamped = C_Navigation.WasClampedToScreen()
                -- Calculate relative bearing for edge indicator rotation
                local relBearing = 0
                local py, px = UnitPosition("player")
                local facing = GetPlayerFacing()
                if px and py and facing and state.targetWorldX and state.targetWorldY then
                    local bearing = Utils.Bearing(px, py, state.targetWorldX, state.targetWorldY)
                    relBearing = bearing - facing
                end
                return cx, cy, not clamped, relBearing
            end
        end
    end

    -- Method 2: Bearing-based projection
    local py, px = UnitPosition("player")
    if not px or not py then return nil, nil, false, 0 end
    local facing = GetPlayerFacing()
    if not facing then return nil, nil, false, 0 end

    local targetX = state.targetWorldX
    local targetY = state.targetWorldY
    if not targetX or not targetY then return nil, nil, false, 0 end

    local bearing = Utils.Bearing(px, py, targetX, targetY)
    local relBearing = bearing - facing

    local dx = targetX - px
    local dy = targetY - py
    local cosF = math_cos(-facing)
    local sinF = math_sin(-facing)
    local relX = dx * cosF - dy * sinF
    local relY = dx * sinF + dy * cosF

    local sw = GetScreenWidth()
    local sh = GetScreenHeight()

    if relY > 0.5 then
        -- Target is in front of player
        local hAngle = math_atan2(relX, relY)
        local hFov = math_pi / 2
        local screenX = sw * 0.5 + (hAngle / hFov) * sw * 0.5
        local dist = math_sqrt(relX * relX + relY * relY)
        local screenY = sh * 0.35 + Utils.Remap(dist, 5, 200, sh * 0.15, 0)

        local margin = 60
        local onScreen = screenX >= -margin and screenX <= sw + margin
                         and screenY >= -margin and screenY <= sh + margin
        return screenX, screenY, onScreen, relBearing
    else
        -- Target is behind or beside player
        -- Return projected edge position
        local screenDX = math_sin(relBearing)
        local screenDY = math_cos(relBearing)
        local edgeCfg = Config.EDGE_INDICATOR
        local halfW = sw / 2 - edgeCfg.MARGIN
        local halfH = sh / 2 - edgeCfg.MARGIN

        local scaleX = screenDX ~= 0 and halfW / math_abs(screenDX) or 1e6
        local scaleY = screenDY ~= 0 and halfH / math_abs(screenDY) or 1e6
        local scale = math_min(scaleX, scaleY)

        local screenX = sw / 2 + screenDX * scale
        local screenY = sh / 2 + screenDY * scale
        return screenX, screenY, false, relBearing
    end
end

------------------------------------------------------------------------
-- EDGE INDICATOR POSITIONING
------------------------------------------------------------------------

local function UpdateEdgeIndicatorPosition(screenX, screenY, relBearing, distance, alpha)
    if not edgeFrame then return end

    local sw = GetScreenWidth()
    local sh = GetScreenHeight()
    local edgeCfg = Config.EDGE_INDICATOR

    -- If we have a screen position (from C_Navigation clamped), use it directly
    -- Otherwise compute from bearing
    local edgeX, edgeY = screenX, screenY

    -- Clamp to screen edge with margin
    edgeX = Utils.Clamp(edgeX, edgeCfg.MARGIN, sw - edgeCfg.MARGIN)
    edgeY = Utils.Clamp(edgeY, edgeCfg.MARGIN, sh - edgeCfg.MARGIN)

    -- Smooth movement (prevent jitter)
    local lerpSpeed = math_min(1, lastElapsed * 8)
    edgeSmoothedX = edgeSmoothedX + (edgeX - edgeSmoothedX) * lerpSpeed
    edgeSmoothedY = edgeSmoothedY + (edgeY - edgeSmoothedY) * lerpSpeed

    edgeFrame:ClearAllPoints()
    edgeFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", edgeSmoothedX, edgeSmoothedY)

    -- Position arrow outside diamond, pointing outward from screen center
    local outwardAngle = math_atan2(edgeSmoothedX - sw / 2, edgeSmoothedY - sh / 2)
    edgeFrame.arrow:SetRotation(-outwardAngle)

    -- Offset arrow from center of diamond in the outward direction
    local arrowOffset = edgeCfg.ARROW_OFFSET
    local arrowDX = math_sin(outwardAngle) * arrowOffset
    local arrowDY = math_cos(outwardAngle) * arrowOffset
    edgeFrame.arrow:ClearAllPoints()
    edgeFrame.arrow:SetPoint("CENTER", edgeFrame, "CENTER", arrowDX, arrowDY)

    -- Distance text
    if distance then
        edgeFrame.distText:SetText(Utils.FormatDistance(distance))
        edgeFrame.distText:Show()
    else
        edgeFrame.distText:Hide()
    end

    edgeFrame:SetAlpha(alpha * 0.9)
    edgeFrame:Show()
end

------------------------------------------------------------------------
-- BEAM + BASE POSITIONING
------------------------------------------------------------------------

local function UpdateChevrons(screenX, screenY, beamHeight, distance, alpha, morphProgress)
    local elevState = DXD.state.elevationState
    local showChevrons = (elevState ~= "level")
        and distance and distance > Config.BEACON.CLOSE_DISTANCE
        and distance < Config.BEACON.FAR_DISTANCE
        and morphProgress < 0.5

    if not showChevrons then
        for _, cf in ipairs(chevronFrames) do cf:Hide() end
        return
    end

    local chevronChar = elevState == "above" and "\226\150\178" or "\226\150\188"
    local chevOffset = Anim:GetChevronOffset()
    local spacing = beamHeight / (#chevronFrames + 1)

    for i, cf in ipairs(chevronFrames) do
        local yPos = screenY + spacing * i + chevOffset
        if yPos > 0 and yPos < screenY + beamHeight then
            cf.text:SetText(chevronChar)
            cf:ClearAllPoints()
            cf:SetPoint("CENTER", UIParent, "BOTTOMLEFT", screenX, yPos)
            cf:SetAlpha(alpha * 0.5)
            cf:Show()
        else
            cf:Hide()
        end
    end
end

local function UpdateBeamAndBase(screenX, screenY, distance)
    if not screenX or not screenY then
        if beamFrame then beamFrame:Hide() end
        if baseFrame then baseFrame:Hide() end
        if fireflyFrame then fireflyFrame:Hide() end
        return
    end

    local morphProgress = Anim:GetMorphProgress()
    local proximityAlpha = Anim:GetProximityAlpha(distance)
    local beamHeight = Anim:GetBeamHeight(distance, screenY)
    local beamWidth = Anim:GetBeamWidth(distance)
    local glowWidth = Anim:GetGlowWidth(distance)
    local pulseAlpha = Anim:GetPulseAlpha(distance)

    -- User settings
    local userOpacity = DXD.db and DXD.db.beamOpacity or 0.90
    local userScale = DXD.db and DXD.db.beaconScale or 1.0
    local widthScale = DXD.db and DXD.db.beamWidthScale or 1.0
    beamWidth = beamWidth * widthScale
    glowWidth = glowWidth * widthScale

    -- Combine alpha factors
    local idleAlpha = math_max(0.40, Anim:GetIdleAlpha())
    local finalAlpha = pulseAlpha * idleAlpha * userOpacity * proximityAlpha

    -- Gentle distance dimming beyond 200y
    if distance and distance > 200 then
        local distDim = Utils.Remap(distance, 200, 500, 1.0, 0.55)
        finalAlpha = finalAlpha * distDim
    end

    -- Fade-in/out transition
    local fadeDelta = targetFadeAlpha - fadeAlpha
    if math_abs(fadeDelta) > 0.01 then
        local speed = fadeDelta > 0 and (1 / Config.ANIMATION.BEACON_FADE_IN) or (1 / Config.ANIMATION.BEACON_FADE_OUT)
        fadeAlpha = fadeAlpha + fadeDelta * math_min(1, speed * lastElapsed)
    else
        fadeAlpha = targetFadeAlpha
    end
    finalAlpha = finalAlpha * fadeAlpha

    -- Masked beam reveal animation
    if targetFadeAlpha > 0 then
        beamMaskScale = math_min(1, beamMaskScale + lastElapsed * 2.5)
    else
        beamMaskScale = math_max(0, beamMaskScale - lastElapsed * 4)
    end

    -- Arrival animation
    local arrivalScale, arrivalAlpha, arrivalComplete = Anim:UpdateArrival()
    if Anim:IsArrivalPlaying() then
        finalAlpha = finalAlpha * arrivalAlpha
    end

    local revealedHeight = beamHeight * beamMaskScale

    -- Clamp beam base to screen bottom (prevents disappearing on camera pan up)
    local beamBaseY = math_max(screenY, 0)
    local visibleHeight = revealedHeight - (beamBaseY - screenY)

    ----------------------------------------------------------------
    -- BEAM RENDERING (thin elegant pillar)
    ----------------------------------------------------------------
    if morphProgress < 0.95 and visibleHeight > 2 and finalAlpha > 0.01 then
        local beamAlpha = finalAlpha * (1 - morphProgress)

        beamFrame:ClearAllPoints()
        beamFrame:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", screenX, beamBaseY)

        -- Core shaft: thin bright center (1.5px default)
        beamFrame.shaft:SetSize(beamWidth, visibleHeight)
        beamFrame.shaft:SetAlpha(beamAlpha * 0.85)

        -- Inner glow: slightly wider (5px default)
        beamFrame.glow:SetSize(glowWidth, visibleHeight)
        beamFrame.glow:SetAlpha(beamAlpha * 0.18)

        -- Outer glow: widest, very soft (12.5px default)
        beamFrame.glow2:SetSize(glowWidth * 2.5, visibleHeight)
        beamFrame.glow2:SetAlpha(beamAlpha * 0.07)

        -- Gradient overlay (fade at top)
        beamFrame.gradient:SetSize(glowWidth * 2.5, visibleHeight)
        beamFrame.gradient:SetAlpha(1)

        -- Base glow
        beamFrame.baseGlow:SetAlpha(beamAlpha * 0.15)
        beamFrame.baseGlow:SetSize(glowWidth * 4, 6)

        beamFrame:SetSize(glowWidth * 2.5, visibleHeight)
        beamFrame:Show()
    else
        beamFrame:Hide()
    end

    ----------------------------------------------------------------
    -- DIAMOND BASE ICON
    ----------------------------------------------------------------
    if morphProgress < 0.8 and screenY > -20 and finalAlpha > 0.01 then
        -- Scale diamond based on distance (subtle perspective)
        local diamondScale = Utils.Remap(distance or 100, 15, 300, 1.1, 0.75) * userScale
        diamondScale = Utils.Clamp(diamondScale, 0.6, 1.3)
        local plateSize = 18 * diamondScale
        local borderSize = 20 * diamondScale
        local iconSize = 14 * diamondScale
        local frameSize = 32 * diamondScale

        baseFrame:SetSize(frameSize, frameSize)
        baseFrame.plate:SetSize(plateSize, plateSize)
        baseFrame.border:SetSize(borderSize, borderSize)
        baseFrame.innerGlow:SetSize(plateSize - 2, plateSize - 2)
        baseFrame.icon:SetSize(iconSize, iconSize)

        baseFrame:ClearAllPoints()
        baseFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", screenX, screenY)
        baseFrame:SetAlpha(finalAlpha * 0.95 * (1 - morphProgress * 0.8))

        -- Distance text
        if distance and baseFrame.distText then
            baseFrame.distText:SetText(Utils.FormatDistance(distance))
        end

        -- Target name
        if DXD.db and DXD.db.showBeaconName ~= false then
            local targetName = DXD.state.targetName
            if targetName and baseFrame.nameText then
                if #targetName > 28 then
                    targetName = string.sub(targetName, 1, 25) .. "..."
                end
                baseFrame.nameText:SetText(targetName)
                baseFrame.nameText:Show()
            end
        elseif baseFrame.nameText then
            baseFrame.nameText:Hide()
        end

        UpdateElevationBadge(distance)
        baseFrame:Show()
    else
        baseFrame:Hide()
        if elevBadge then elevBadge:Hide() end
    end

    ----------------------------------------------------------------
    -- FIREFLY (close range arrival dot)
    ----------------------------------------------------------------
    if morphProgress > 0.05 and finalAlpha > 0.01 then
        local bobOffset = Anim:GetBobOffset()
        local fireflyAlpha = finalAlpha * morphProgress * 0.9

        local fireflySize = 10 * arrivalScale
        fireflyFrame:SetSize(fireflySize, fireflySize)
        fireflyFrame.ring:SetSize(fireflySize * 1.8, fireflySize * 1.8)
        fireflyFrame:ClearAllPoints()
        fireflyFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", screenX, screenY + bobOffset)
        fireflyFrame:SetAlpha(fireflyAlpha)
        fireflyFrame:Show()
    else
        fireflyFrame:Hide()
    end

    -- Chevrons on beam
    UpdateChevrons(screenX, beamBaseY, visibleHeight, distance, finalAlpha, morphProgress)

    if arrivalComplete then
        Beacon:Hide()
        DXD:Debug("Arrival animation complete, beacon hidden")
    end
end

------------------------------------------------------------------------
-- HIDE ALL SUB-FRAMES
------------------------------------------------------------------------

local function HideAllFrames()
    if beamFrame then beamFrame:Hide() end
    if baseFrame then baseFrame:Hide() end
    if edgeFrame then edgeFrame:Hide() end
    if fireflyFrame then fireflyFrame:Hide() end
    if elevBadge then elevBadge:Hide() end
    for _, cf in ipairs(chevronFrames) do cf:Hide() end
end

------------------------------------------------------------------------
-- PUBLIC API
------------------------------------------------------------------------

function Beacon:Show()
    isVisible = true
    targetFadeAlpha = 1
    ApplyBeaconColor(DXD:GetBeaconColor())
    UpdateBaseIcon()
    UpdateEdgeIcon()
end

function Beacon:Hide()
    isVisible = false
    targetFadeAlpha = 0
    beamMaskScale = 0
    HideAllFrames()
end

function Beacon:TriggerArrival()
    Anim:TriggerArrival()
end

function Beacon:OnTargetChanged()
    self:Show()
    Anim:Reset()
    fadeAlpha = 0
    beamMaskScale = 0
    targetFadeAlpha = 1
    lastOnScreen = true
    -- Reset edge smoothing to target position
    local state = DXD.state
    local sx, sy = GetTargetScreenInfo(state)
    if sx and sy then
        edgeSmoothedX = sx
        edgeSmoothedY = sy
    end
    ApplyBeaconColor(DXD:GetBeaconColor())
    UpdateBaseIcon()
    UpdateEdgeIcon()
end

function Beacon:OnTargetCleared()
    self:Hide()
    Anim:Reset()
end

------------------------------------------------------------------------
-- MAIN UPDATE
------------------------------------------------------------------------

function Beacon:OnUpdate(elapsed)
    if not isVisible then return end
    if not DXD.state.hasTarget then return end

    lastElapsed = elapsed

    local state = DXD.state

    -- Update animations
    Anim:UpdateMorph(state.distance3D, elapsed)
    Anim:UpdateIdleFade(state.playerMoving, elapsed)

    -- Get screen position and on-screen status
    local screenX, screenY, onScreen, relBearing = GetTargetScreenInfo(state)

    if not screenX or not screenY then
        HideAllFrames()
        return
    end

    -- Compute fade alpha for the beacon
    local idleAlpha = math_max(0.40, Anim:GetIdleAlpha())
    local userOpacity = DXD.db and DXD.db.beamOpacity or 0.90
    local baseAlpha = idleAlpha * userOpacity * fadeAlpha

    if onScreen then
        -- TARGET ON SCREEN: show beam + diamond base, hide edge indicator
        if edgeFrame then edgeFrame:Hide() end
        UpdateBeamAndBase(screenX, screenY, state.distance3D)
        ApplyBeaconColor(DXD:GetBeaconColor())
        lastOnScreen = true
    else
        -- TARGET OFF SCREEN: hide beam + base, show edge indicator
        if beamFrame then beamFrame:Hide() end
        if baseFrame then baseFrame:Hide() end
        if fireflyFrame then fireflyFrame:Hide() end
        if elevBadge then elevBadge:Hide() end
        for _, cf in ipairs(chevronFrames) do cf:Hide() end

        -- Update fade for edge indicator
        local fadeDelta = targetFadeAlpha - fadeAlpha
        if math_abs(fadeDelta) > 0.01 then
            local speed = fadeDelta > 0 and (1 / Config.ANIMATION.BEACON_FADE_IN) or (1 / Config.ANIMATION.BEACON_FADE_OUT)
            fadeAlpha = fadeAlpha + fadeDelta * math_min(1, speed * lastElapsed)
        else
            fadeAlpha = targetFadeAlpha
        end

        local edgeAlpha = fadeAlpha * userOpacity * idleAlpha
        UpdateEdgeIndicatorPosition(screenX, screenY, relBearing, state.distance3D, edgeAlpha)
        ApplyBeaconColor(DXD:GetBeaconColor())
        lastOnScreen = false
    end
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function Beacon:Initialize()
    CreateBeaconFrames()
    -- Initialize edge smoothing to screen center
    edgeSmoothedX = GetScreenWidth() / 2
    edgeSmoothedY = GetScreenHeight() / 2
    DXD:Debug("Beacon initialized (diamond base + edge indicator)")
end
