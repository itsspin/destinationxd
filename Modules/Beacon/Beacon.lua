------------------------------------------------------------------------
-- DestinationXD - Beacon.lua
-- In-world waypoint beacon: thin elegant beam, diamond base, edge indicator
-- Visual approach: WaypointUI-inspired. Thin laser core + soft radial
-- glow layers using Indicator-Gray (soft circle gradient). Diamond base
-- using Waypoint atlas. Off-screen edge indicator at screen border.
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local Beacon = {}
DXD:RegisterModule("Beacon", Beacon)

local Utils = DXD.Utils
local Config = DXD.Config
local Anim -- set in Initialize (BeaconAnimations)

-- Lua refs
local math_sin   = math.sin
local math_cos   = math.cos
local math_atan2  = math.atan2
local math_abs   = math.abs
local math_min   = math.min
local math_max   = math.max
local math_sqrt  = math.sqrt
local math_rad   = math.rad
local math_pi    = math.pi

------------------------------------------------------------------------
-- VISUAL FRAMES
------------------------------------------------------------------------
local beamFrame        -- thin beam column (core + 2 glow layers + gradient)
local baseFrame        -- diamond icon at beam base
local edgeFrame        -- off-screen edge indicator
local fireflyFrame     -- close-range floating dot
local elevBadge        -- up/down badge on base
local chevronFrames = {}

------------------------------------------------------------------------
-- STATE
------------------------------------------------------------------------
local isVisible        = false
local currentColor     = nil
local fadeAlpha        = 0
local targetFadeAlpha  = 0
local beamMaskScale    = 0
local lastElapsed      = 0.016
local edgeSmoothedX, edgeSmoothedY = 0, 0
local shimmerTime      = 0  -- for subtle beam breathing

------------------------------------------------------------------------
-- ICON MAPS
------------------------------------------------------------------------
local OBJECTIVE_ICONS = {
    quest    = "QuestNormal",
    waypoint = "Waypoint-MapPin-ChatIcon",
    corpse   = "poi-graveyard-neutral",
    travel   = "FlightMaster",
    tomtom   = "Waypoint-MapPin-ChatIcon",
    dungeon  = "Dungeon",
    flight   = "FlightMaster",
}

local OBJECTIVE_FALLBACK_COLORS = {
    quest    = {r=1.0, g=0.84, b=0.0},
    waypoint = {r=0.4, g=0.85, b=1.0},
    corpse   = {r=0.9, g=0.25, b=0.25},
    travel   = {r=0.88,g=0.88, b=0.92},
    tomtom   = {r=1.0, g=0.55, b=0.0},
    dungeon  = {r=0.7, g=0.45, b=1.0},
    flight   = {r=0.27,g=1.0,  b=0.53},
}

------------------------------------------------------------------------
-- SOFT GLOW TEXTURE HELPER
-- Uses a circular gradient texture stretched into a tall column.
-- The radial falloff gives us natural soft edges horizontally,
-- which is what makes the beam look like a pillar of light
-- rather than a hard rectangle.
------------------------------------------------------------------------
local SOFT_GLOW_TEXTURE = "Interface\\COMMON\\Indicator-Gray"
-- Fallback if Indicator-Gray doesn't exist in this client:
local SOFT_GLOW_FALLBACK = "Interface\\COMMON\\Indicator-Yellow"
-- Final fallback:
local HARD_TEXTURE = "Interface\\BUTTONS\\WHITE8X8"

local function SetSoftTexture(tex)
    -- Try the preferred soft glow, fall back gracefully
    local ok = pcall(tex.SetTexture, tex, SOFT_GLOW_TEXTURE)
    if not ok or not tex:GetTexture() then
        ok = pcall(tex.SetTexture, tex, SOFT_GLOW_FALLBACK)
    end
    if not ok or not tex:GetTexture() then
        tex:SetTexture(HARD_TEXTURE)
    end
end

------------------------------------------------------------------------
-- GRADIENT HELPER (handles API differences across WoW versions)
------------------------------------------------------------------------
local function ApplyVerticalGradient(tex)
    local ok = pcall(function()
        tex:SetGradient("VERTICAL",
            CreateColor(1, 1, 1, 1),
            CreateColor(0, 0, 0, 0))
    end)
    if not ok then
        pcall(function()
            tex:SetGradientAlpha("VERTICAL",
                1, 1, 1, 1,
                0, 0, 0, 0)
        end)
    end
end

------------------------------------------------------------------------
-- FRAME CREATION
------------------------------------------------------------------------

local function CreateBeamFrame()
    beamFrame = CreateFrame("Frame", "DXDBeaconBeam", UIParent)
    beamFrame:SetFrameStrata("BACKGROUND")
    beamFrame:SetFrameLevel(1)
    beamFrame:Hide()

    -- Layer 1: Core shaft (very thin, bright)
    -- WHITE8X8 is fine here because at 1-2px width, edges are invisible
    beamFrame.shaft = beamFrame:CreateTexture(nil, "ARTWORK", nil, 3)
    beamFrame.shaft:SetTexture(HARD_TEXTURE)
    beamFrame.shaft:SetBlendMode("ADD")
    beamFrame.shaft:SetPoint("BOTTOM")

    -- Layer 2: Inner glow (soft circle gradient, stretched tall)
    -- The radial falloff gives natural soft horizontal edges
    beamFrame.glow = beamFrame:CreateTexture(nil, "ARTWORK", nil, 1)
    SetSoftTexture(beamFrame.glow)
    beamFrame.glow:SetBlendMode("ADD")
    beamFrame.glow:SetPoint("BOTTOM")

    -- Layer 3: Outer glow (wider, even softer)
    beamFrame.glow2 = beamFrame:CreateTexture(nil, "ARTWORK", nil, 0)
    SetSoftTexture(beamFrame.glow2)
    beamFrame.glow2:SetBlendMode("ADD")
    beamFrame.glow2:SetPoint("BOTTOM")

    -- Layer 4: Gradient overlay (MOD blend to fade beam at top)
    beamFrame.gradient = beamFrame:CreateTexture(nil, "ARTWORK", nil, 4)
    beamFrame.gradient:SetTexture(HARD_TEXTURE)
    beamFrame.gradient:SetBlendMode("MOD")
    beamFrame.gradient:SetPoint("BOTTOM")
    ApplyVerticalGradient(beamFrame.gradient)

    -- Layer 5: Secondary gradient for smoother fade (upper portion only)
    beamFrame.gradient2 = beamFrame:CreateTexture(nil, "ARTWORK", nil, 5)
    beamFrame.gradient2:SetTexture(HARD_TEXTURE)
    beamFrame.gradient2:SetBlendMode("MOD")
    ApplyVerticalGradient(beamFrame.gradient2)

    -- Base glow (soft pool of light at beam foot)
    beamFrame.baseGlow = beamFrame:CreateTexture(nil, "ARTWORK", nil, -1)
    SetSoftTexture(beamFrame.baseGlow)
    beamFrame.baseGlow:SetBlendMode("ADD")
    beamFrame.baseGlow:SetPoint("BOTTOM", 0, -3)
    beamFrame.baseGlow:SetSize(20, 6)
    beamFrame.baseGlow:SetAlpha(0.08)
end

local function CreateBaseFrame()
    baseFrame = CreateFrame("Frame", "DXDBeaconBase", UIParent)
    baseFrame:SetFrameStrata("BACKGROUND")
    baseFrame:SetFrameLevel(5)
    baseFrame:SetSize(28, 28)
    baseFrame:Hide()

    -- Try to use WoW's native waypoint diamond atlas (clean look)
    baseFrame.diamond = baseFrame:CreateTexture(nil, "BACKGROUND")
    local atlasOk = pcall(function()
        baseFrame.diamond:SetAtlas("Waypoint-MapPin-ChatIcon")
    end)
    if not atlasOk then
        -- Fallback: rotated white square to make a diamond
        baseFrame.diamond:SetTexture(HARD_TEXTURE)
        baseFrame.diamond:SetRotation(math_rad(45))
    end
    baseFrame.diamond:SetSize(22, 22)
    baseFrame.diamond:SetPoint("CENTER")

    -- Dark plate behind the diamond (for contrast)
    baseFrame.plate = baseFrame:CreateTexture(nil, "BACKGROUND", nil, -2)
    baseFrame.plate:SetTexture(HARD_TEXTURE)
    baseFrame.plate:SetRotation(math_rad(45))
    baseFrame.plate:SetSize(17, 17)
    baseFrame.plate:SetPoint("CENTER")
    baseFrame.plate:SetVertexColor(0.02, 0.02, 0.05, 0.75)

    -- Border glow (subtle color ring around diamond)
    baseFrame.borderGlow = baseFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
    SetSoftTexture(baseFrame.borderGlow)
    baseFrame.borderGlow:SetBlendMode("ADD")
    baseFrame.borderGlow:SetSize(30, 30)
    baseFrame.borderGlow:SetPoint("CENTER")
    baseFrame.borderGlow:SetAlpha(0.10)

    -- Target name text above diamond
    baseFrame.nameText = baseFrame:CreateFontString(nil, "OVERLAY")
    baseFrame.nameText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    baseFrame.nameText:SetShadowColor(0, 0, 0, 0.9)
    baseFrame.nameText:SetShadowOffset(1, -1)
    baseFrame.nameText:SetPoint("BOTTOM", baseFrame, "TOP", 0, 3)
    baseFrame.nameText:SetJustifyH("CENTER")
    baseFrame.nameText:SetWidth(200)
    baseFrame.nameText:SetWordWrap(false)

    -- Distance text below diamond
    baseFrame.distText = baseFrame:CreateFontString(nil, "OVERLAY")
    baseFrame.distText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    baseFrame.distText:SetShadowColor(0, 0, 0, 0.9)
    baseFrame.distText:SetShadowOffset(1, -1)
    baseFrame.distText:SetPoint("TOP", baseFrame, "BOTTOM", 0, -1)
    baseFrame.distText:SetJustifyH("CENTER")
end

local function CreateEdgeIndicator()
    edgeFrame = CreateFrame("Frame", "DXDEdgeIndicator", UIParent)
    edgeFrame:SetFrameStrata("HIGH")
    edgeFrame:SetFrameLevel(20)
    edgeFrame:SetSize(32, 32)
    edgeFrame:Hide()

    -- Diamond icon (try atlas, fallback to rotated square)
    edgeFrame.diamond = edgeFrame:CreateTexture(nil, "BACKGROUND")
    local atlasOk = pcall(function()
        edgeFrame.diamond:SetAtlas("Waypoint-MapPin-ChatIcon")
    end)
    if not atlasOk then
        edgeFrame.diamond:SetTexture(HARD_TEXTURE)
        edgeFrame.diamond:SetRotation(math_rad(45))
    end
    edgeFrame.diamond:SetSize(18, 18)
    edgeFrame.diamond:SetPoint("CENTER")

    -- Dark plate behind diamond
    edgeFrame.plate = edgeFrame:CreateTexture(nil, "BACKGROUND", nil, -2)
    edgeFrame.plate:SetTexture(HARD_TEXTURE)
    edgeFrame.plate:SetRotation(math_rad(45))
    edgeFrame.plate:SetSize(13, 13)
    edgeFrame.plate:SetPoint("CENTER")
    edgeFrame.plate:SetVertexColor(0.02, 0.02, 0.05, 0.80)

    -- Border glow
    edgeFrame.borderGlow = edgeFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
    SetSoftTexture(edgeFrame.borderGlow)
    edgeFrame.borderGlow:SetBlendMode("ADD")
    edgeFrame.borderGlow:SetSize(24, 24)
    edgeFrame.borderGlow:SetPoint("CENTER")
    edgeFrame.borderGlow:SetAlpha(0.12)

    -- Directional arrow (points outward toward target)
    edgeFrame.arrow = edgeFrame:CreateTexture(nil, "ARTWORK", nil, 1)
    edgeFrame.arrow:SetTexture("Interface\\MINIMAP\\ROTATING-MINIMAPGROUPARROW")
    edgeFrame.arrow:SetSize(10, 10)
    edgeFrame.arrow:SetPoint("CENTER")
    edgeFrame.arrow:SetBlendMode("ADD")
    edgeFrame.arrow:SetAlpha(0.6)

    -- Distance text
    edgeFrame.distText = edgeFrame:CreateFontString(nil, "OVERLAY")
    edgeFrame.distText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    edgeFrame.distText:SetShadowColor(0, 0, 0, 0.9)
    edgeFrame.distText:SetShadowOffset(1, -1)
    edgeFrame.distText:SetPoint("TOP", edgeFrame, "BOTTOM", 0, -1)
    edgeFrame.distText:SetJustifyH("CENTER")
end

local function CreateFireflyFrame()
    fireflyFrame = CreateFrame("Frame", "DXDBeaconFirefly", UIParent)
    fireflyFrame:SetFrameStrata("BACKGROUND")
    fireflyFrame:SetFrameLevel(4)
    fireflyFrame:SetSize(8, 8)
    fireflyFrame:Hide()

    fireflyFrame.dot = fireflyFrame:CreateTexture(nil, "ARTWORK")
    SetSoftTexture(fireflyFrame.dot)
    fireflyFrame.dot:SetBlendMode("ADD")
    fireflyFrame.dot:SetAllPoints()

    fireflyFrame.ring = fireflyFrame:CreateTexture(nil, "ARTWORK", nil, -1)
    fireflyFrame.ring:SetTexture("Interface\\COMMON\\RingBorder")
    fireflyFrame.ring:SetBlendMode("ADD")
    fireflyFrame.ring:SetSize(16, 16)
    fireflyFrame.ring:SetPoint("CENTER")
    fireflyFrame.ring:SetAlpha(0.15)
end

local function CreateElevBadge()
    elevBadge = CreateFrame("Frame", "DXDElevBadge", baseFrame)
    elevBadge:SetFrameStrata("BACKGROUND")
    elevBadge:SetFrameLevel(7)
    elevBadge:SetSize(14, 14)
    elevBadge:SetPoint("TOPLEFT", baseFrame, "TOPRIGHT", 1, 1)
    elevBadge:Hide()

    elevBadge.bg = elevBadge:CreateTexture(nil, "BACKGROUND")
    elevBadge.bg:SetTexture(HARD_TEXTURE)
    elevBadge.bg:SetAllPoints()
    elevBadge.bg:SetVertexColor(0.02, 0.02, 0.05, 0.80)

    elevBadge.text = elevBadge:CreateFontString(nil, "OVERLAY")
    elevBadge.text:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    elevBadge.text:SetShadowColor(0, 0, 0, 0.8)
    elevBadge.text:SetShadowOffset(1, -1)
    elevBadge.text:SetPoint("CENTER")
end

local function CreateChevrons()
    for i = 1, 4 do
        local cf = CreateFrame("Frame", "DXDChevron" .. i, UIParent)
        cf:SetFrameStrata("BACKGROUND")
        cf:SetFrameLevel(3)
        cf:SetSize(8, 8)
        cf:Hide()
        cf.text = cf:CreateFontString(nil, "OVERLAY")
        cf.text:SetFont("Fonts\\FRIZQT__.TTF", 7, "OUTLINE")
        cf.text:SetPoint("CENTER")
        cf.text:SetShadowColor(0, 0, 0, 0.5)
        cf.text:SetShadowOffset(1, -1)
        chevronFrames[i] = cf
    end
end

------------------------------------------------------------------------
-- COLOR APPLICATION
------------------------------------------------------------------------

local function ApplyColor(color)
    if not color then return end
    currentColor = color
    local r, g, b = color.r, color.g, color.b

    -- Beam: tint all layers
    if beamFrame then
        if beamFrame.shaft    then beamFrame.shaft:SetVertexColor(r, g, b, 1) end
        if beamFrame.glow     then beamFrame.glow:SetVertexColor(r, g, b, 1) end
        if beamFrame.glow2    then beamFrame.glow2:SetVertexColor(r, g, b, 1) end
        if beamFrame.baseGlow then beamFrame.baseGlow:SetVertexColor(r, g, b, 1) end
    end

    -- Diamond base
    if baseFrame then
        if baseFrame.diamond    then baseFrame.diamond:SetVertexColor(r*0.6+0.4, g*0.6+0.4, b*0.6+0.4, 0.9) end
        if baseFrame.borderGlow then baseFrame.borderGlow:SetVertexColor(r, g, b, 0.10) end
        if baseFrame.distText   then baseFrame.distText:SetTextColor(r*0.8+0.2, g*0.8+0.2, b*0.8+0.2, 0.75) end
        if baseFrame.nameText   then baseFrame.nameText:SetTextColor(r*0.6+0.4, g*0.6+0.4, b*0.6+0.4, 0.55) end
    end

    -- Edge indicator
    if edgeFrame then
        if edgeFrame.diamond    then edgeFrame.diamond:SetVertexColor(r*0.6+0.4, g*0.6+0.4, b*0.6+0.4, 0.85) end
        if edgeFrame.borderGlow then edgeFrame.borderGlow:SetVertexColor(r, g, b, 0.12) end
        if edgeFrame.arrow      then edgeFrame.arrow:SetVertexColor(r, g, b, 0.6) end
        if edgeFrame.distText   then edgeFrame.distText:SetTextColor(r*0.8+0.2, g*0.8+0.2, b*0.8+0.2, 0.65) end
    end

    -- Firefly
    if fireflyFrame then
        if fireflyFrame.dot  then fireflyFrame.dot:SetVertexColor(r, g, b, 0.85) end
        if fireflyFrame.ring then fireflyFrame.ring:SetVertexColor(r, g, b, 0.15) end
    end

    -- Chevrons (elevation color)
    local elevState = DXD.state.elevationState
    local ec = Config.COLORS.ELEV_LEVEL
    if elevState == "above" then ec = Config.COLORS.ELEV_ABOVE
    elseif elevState == "below" then ec = Config.COLORS.ELEV_BELOW end
    for _, cf in ipairs(chevronFrames) do
        cf.text:SetTextColor(ec.r, ec.g, ec.b, ec.a)
    end
end

------------------------------------------------------------------------
-- ICON HELPERS
------------------------------------------------------------------------

local function SetObjectiveIcon(tex, targetType)
    if not tex then return end
    local atlas = OBJECTIVE_ICONS[targetType or "waypoint"]
    if atlas then
        local ok = pcall(function() tex:SetAtlas(atlas) end)
        if ok then
            tex:SetTexCoord(0, 1, 0, 1)
            tex:SetDesaturated(true)
            if currentColor then
                tex:SetVertexColor(currentColor.r, currentColor.g, currentColor.b, 0.85)
            end
            tex:Show()
            return
        end
    end
    -- Fallback: soft dot with color
    SetSoftTexture(tex)
    local fc = OBJECTIVE_FALLBACK_COLORS[targetType or "waypoint"]
    if fc then tex:SetVertexColor(fc.r, fc.g, fc.b, 0.85) end
    tex:Show()
end

------------------------------------------------------------------------
-- SCREEN POSITION
------------------------------------------------------------------------

local function GetTargetScreenInfo(state)
    -- Method 1: C_Navigation (supertracked waypoints)
    if C_Navigation and C_Navigation.HasValidScreenPosition
       and C_Navigation.HasValidScreenPosition() then
        local navFrame = C_Navigation.GetFrame()
        if navFrame and navFrame:IsShown() then
            local cx, cy = navFrame:GetCenter()
            if cx and cy then
                local clamped = C_Navigation.WasClampedToScreen()
                local relBearing = 0
                local py, px = UnitPosition("player")
                local facing = GetPlayerFacing()
                if px and py and facing
                   and state.targetWorldX and state.targetWorldY then
                    relBearing = Utils.Bearing(px, py,
                        state.targetWorldX, state.targetWorldY) - facing
                end
                return cx, cy, not clamped, relBearing
            end
        end
    end

    -- Method 2: Bearing projection
    local py, px = UnitPosition("player")
    if not px or not py then return nil, nil, false, 0 end
    local facing = GetPlayerFacing()
    if not facing then return nil, nil, false, 0 end
    local tx, ty = state.targetWorldX, state.targetWorldY
    if not tx or not ty then return nil, nil, false, 0 end

    local bearing = Utils.Bearing(px, py, tx, ty)
    local relBearing = bearing - facing

    local dx, dy = tx - px, ty - py
    local cosF, sinF = math_cos(-facing), math_sin(-facing)
    local relX = dx*cosF - dy*sinF
    local relY = dx*sinF + dy*cosF

    local sw, sh = GetScreenWidth(), GetScreenHeight()

    if relY > 0.5 then
        local hAngle = math_atan2(relX, relY)
        local hFov   = math_pi / 2
        local screenX = sw * 0.5 + (hAngle / hFov) * sw * 0.5
        local dist = math_sqrt(relX*relX + relY*relY)
        local screenY = sh * 0.35 + Utils.Remap(dist, 5, 200, sh*0.15, 0)

        local margin = 60
        local onScreen = screenX >= -margin and screenX <= sw + margin
                     and screenY >= -margin and screenY <= sh + margin
        return screenX, screenY, onScreen, relBearing
    else
        -- Behind/beside: project to screen edge for edge indicator
        local sdx, sdy = math_sin(relBearing), math_cos(relBearing)
        local edgeCfg = Config.EDGE_INDICATOR
        local halfW = sw/2 - edgeCfg.MARGIN
        local halfH = sh/2 - edgeCfg.MARGIN
        local scX = sdx ~= 0 and halfW / math_abs(sdx) or 1e6
        local scY = sdy ~= 0 and halfH / math_abs(sdy) or 1e6
        local sc = math_min(scX, scY)
        return sw/2 + sdx*sc, sh/2 + sdy*sc, false, relBearing
    end
end

------------------------------------------------------------------------
-- EDGE INDICATOR UPDATE
------------------------------------------------------------------------

local function UpdateEdgeIndicator(screenX, screenY, relBearing, distance, alpha)
    if not edgeFrame then return end
    local sw, sh = GetScreenWidth(), GetScreenHeight()
    local ecfg = Config.EDGE_INDICATOR

    local edgeX = Utils.Clamp(screenX, ecfg.MARGIN, sw - ecfg.MARGIN)
    local edgeY = Utils.Clamp(screenY, ecfg.MARGIN, sh - ecfg.MARGIN)

    -- Smooth interpolation
    local spd = math_min(1, lastElapsed * 8)
    edgeSmoothedX = edgeSmoothedX + (edgeX - edgeSmoothedX) * spd
    edgeSmoothedY = edgeSmoothedY + (edgeY - edgeSmoothedY) * spd

    edgeFrame:ClearAllPoints()
    edgeFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", edgeSmoothedX, edgeSmoothedY)

    -- Arrow points outward from screen center
    local outAngle = math_atan2(edgeSmoothedX - sw/2, edgeSmoothedY - sh/2)
    edgeFrame.arrow:SetRotation(-outAngle)
    local ao = ecfg.ARROW_OFFSET
    edgeFrame.arrow:ClearAllPoints()
    edgeFrame.arrow:SetPoint("CENTER", edgeFrame, "CENTER",
        math_sin(outAngle)*ao, math_cos(outAngle)*ao)

    if distance then
        edgeFrame.distText:SetText(Utils.FormatDistance(distance))
        edgeFrame.distText:Show()
    else
        edgeFrame.distText:Hide()
    end

    edgeFrame:SetAlpha(alpha * 0.85)
    edgeFrame:Show()
end

------------------------------------------------------------------------
-- BEAM + BASE UPDATE (the visual core)
------------------------------------------------------------------------

local function UpdateBeamAndBase(screenX, screenY, distance)
    if not screenX or not screenY then
        if beamFrame    then beamFrame:Hide() end
        if baseFrame    then baseFrame:Hide() end
        if fireflyFrame then fireflyFrame:Hide() end
        return
    end

    -- Animation values
    local morphProg   = Anim:GetMorphProgress()
    local proxAlpha   = Anim:GetProximityAlpha(distance)
    local beamHeight  = Anim:GetBeamHeight(distance, screenY)
    local beamWidth   = Anim:GetBeamWidth(distance)
    local glowWidth   = Anim:GetGlowWidth(distance)
    local pulseAlpha  = Anim:GetPulseAlpha(distance)

    -- User settings
    local userOpacity  = DXD.db and DXD.db.beamOpacity or 0.90
    local userScale    = DXD.db and DXD.db.beaconScale or 1.0
    local widthScale   = DXD.db and DXD.db.beamWidthScale or 1.0
    beamWidth  = beamWidth  * widthScale
    glowWidth  = glowWidth  * widthScale

    -- Combine alpha factors
    local idleAlpha = math_max(0.45, Anim:GetIdleAlpha())

    -- Subtle shimmer: gentle sine wave breathing on the beam
    local shimmer = 0.92 + 0.08 * math_sin(shimmerTime * 1.8)

    local finalAlpha = pulseAlpha * idleAlpha * userOpacity * proxAlpha * shimmer

    -- Distance dimming (beyond 250y)
    if distance and distance > 250 then
        finalAlpha = finalAlpha * Utils.Remap(distance, 250, 600, 1.0, 0.50)
    end

    -- Fade transition
    local fadeDelta = targetFadeAlpha - fadeAlpha
    if math_abs(fadeDelta) > 0.005 then
        local speed = fadeDelta > 0
            and (1 / Config.ANIMATION.BEACON_FADE_IN)
            or  (1 / Config.ANIMATION.BEACON_FADE_OUT)
        fadeAlpha = fadeAlpha + fadeDelta * math_min(1, speed * lastElapsed)
    else
        fadeAlpha = targetFadeAlpha
    end
    finalAlpha = finalAlpha * fadeAlpha

    -- Masked beam reveal
    if targetFadeAlpha > 0 then
        beamMaskScale = math_min(1, beamMaskScale + lastElapsed * 2.5)
    else
        beamMaskScale = math_max(0, beamMaskScale - lastElapsed * 4)
    end

    -- Arrival animation
    local arrScale, arrAlpha, arrComplete = Anim:UpdateArrival()
    if Anim:IsArrivalPlaying() then
        finalAlpha = finalAlpha * arrAlpha
    end

    local revealedH  = beamHeight * beamMaskScale
    local beamBaseY  = math_max(screenY, 0)   -- clamp to screen bottom
    local visibleH   = revealedH - (beamBaseY - screenY)

    ----------------------------------------------------------------
    -- BEAM RENDERING
    ----------------------------------------------------------------
    if morphProg < 0.95 and visibleH > 2 and finalAlpha > 0.01 then
        local bAlpha = finalAlpha * (1 - morphProg)
        local sw = GetScreenWidth()

        beamFrame:ClearAllPoints()
        beamFrame:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", screenX, beamBaseY)
        beamFrame:SetSize(glowWidth * 3, visibleH)

        -- Core shaft: thin, bright
        beamFrame.shaft:SetSize(beamWidth, visibleH)
        beamFrame.shaft:SetAlpha(bAlpha * 0.80)

        -- Inner glow: soft radial texture gives natural edge falloff
        beamFrame.glow:SetSize(glowWidth, visibleH)
        beamFrame.glow:SetAlpha(bAlpha * 0.14)

        -- Outer glow: even softer
        beamFrame.glow2:SetSize(glowWidth * 2.5, visibleH)
        beamFrame.glow2:SetAlpha(bAlpha * 0.05)

        -- Gradient overlay (full beam height, fades top)
        beamFrame.gradient:SetSize(glowWidth * 3, visibleH)
        beamFrame.gradient:SetAlpha(1)

        -- Second gradient for extra-smooth top falloff (upper 40%)
        local topH = visibleH * 0.4
        beamFrame.gradient2:ClearAllPoints()
        beamFrame.gradient2:SetPoint("TOP", beamFrame, "TOP")
        beamFrame.gradient2:SetSize(glowWidth * 3, topH)
        beamFrame.gradient2:SetAlpha(0.7)

        -- Base glow pool
        beamFrame.baseGlow:SetAlpha(bAlpha * 0.10)
        beamFrame.baseGlow:SetSize(glowWidth * 3, 5)

        beamFrame:Show()
    else
        beamFrame:Hide()
    end

    ----------------------------------------------------------------
    -- DIAMOND BASE
    ----------------------------------------------------------------
    if morphProg < 0.8 and screenY > -15 and finalAlpha > 0.01 then
        -- Perspective scaling: smaller at distance, larger up close
        local dScale = Utils.Remap(distance or 100, 20, 400, 1.05, 0.65) * userScale
        dScale = Utils.Clamp(dScale, 0.55, 1.2)

        local dSize = 22 * dScale
        baseFrame:SetSize(28 * dScale, 28 * dScale)
        baseFrame.diamond:SetSize(dSize, dSize)
        baseFrame.plate:SetSize(dSize * 0.77, dSize * 0.77)
        baseFrame.borderGlow:SetSize(dSize * 1.4, dSize * 1.4)

        baseFrame:ClearAllPoints()
        baseFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", screenX, screenY)
        baseFrame:SetAlpha(finalAlpha * 0.92 * (1 - morphProg * 0.8))

        -- Distance
        if distance and baseFrame.distText then
            baseFrame.distText:SetText(Utils.FormatDistance(distance))
        end

        -- Name
        if DXD.db and DXD.db.showBeaconName ~= false then
            local name = DXD.state.targetName
            if name and baseFrame.nameText then
                if #name > 30 then name = name:sub(1, 27) .. "..." end
                baseFrame.nameText:SetText(name)
                baseFrame.nameText:Show()
            end
        elseif baseFrame.nameText then
            baseFrame.nameText:Hide()
        end

        -- Elevation badge
        local elevState = DXD.state.elevationState
        local vertDist  = DXD.state.distanceVertical or 0
        if elevBadge then
            if elevState ~= "level" and distance and distance > 5 and vertDist > 5 then
                local ec = elevState == "above"
                    and Config.COLORS.ELEV_ABOVE or Config.COLORS.ELEV_BELOW
                local sym = elevState == "above" and "\226\150\178" or "\226\150\188"
                elevBadge.text:SetText(sym)
                elevBadge.text:SetTextColor(ec.r, ec.g, ec.b, 0.9)
                elevBadge:Show()
            else
                elevBadge:Hide()
            end
        end

        baseFrame:Show()
    else
        baseFrame:Hide()
        if elevBadge then elevBadge:Hide() end
    end

    ----------------------------------------------------------------
    -- FIREFLY (close range)
    ----------------------------------------------------------------
    if morphProg > 0.05 and finalAlpha > 0.01 then
        local bob = Anim:GetBobOffset()
        local fAlpha = finalAlpha * morphProg * 0.85
        local fSize = 8 * arrScale
        fireflyFrame:SetSize(fSize, fSize)
        fireflyFrame.ring:SetSize(fSize * 2, fSize * 2)
        fireflyFrame:ClearAllPoints()
        fireflyFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", screenX, screenY + bob)
        fireflyFrame:SetAlpha(fAlpha)
        fireflyFrame:Show()
    else
        fireflyFrame:Hide()
    end

    ----------------------------------------------------------------
    -- ELEVATION CHEVRONS ON BEAM
    ----------------------------------------------------------------
    local elevState = DXD.state.elevationState
    local showChev = (elevState ~= "level")
        and distance and distance > Config.BEACON.CLOSE_DISTANCE
        and distance < Config.BEACON.FAR_DISTANCE
        and morphProg < 0.5

    if showChev then
        local ch = elevState == "above" and "\226\150\178" or "\226\150\188"
        local co = Anim:GetChevronOffset()
        local sp = visibleH / (#chevronFrames + 1)
        for i, cf in ipairs(chevronFrames) do
            local yp = beamBaseY + sp * i + co
            if yp > 0 and yp < beamBaseY + visibleH then
                cf.text:SetText(ch)
                cf:ClearAllPoints()
                cf:SetPoint("CENTER", UIParent, "BOTTOMLEFT", screenX, yp)
                cf:SetAlpha(finalAlpha * 0.40)
                cf:Show()
            else
                cf:Hide()
            end
        end
    else
        for _, cf in ipairs(chevronFrames) do cf:Hide() end
    end

    if arrComplete then
        Beacon:Hide()
    end
end

------------------------------------------------------------------------
-- HIDE ALL
------------------------------------------------------------------------

local function HideAll()
    if beamFrame    then beamFrame:Hide() end
    if baseFrame    then baseFrame:Hide() end
    if edgeFrame    then edgeFrame:Hide() end
    if fireflyFrame then fireflyFrame:Hide() end
    if elevBadge    then elevBadge:Hide() end
    for _, cf in ipairs(chevronFrames) do cf:Hide() end
end

------------------------------------------------------------------------
-- PUBLIC API
------------------------------------------------------------------------

function Beacon:Show()
    isVisible = true
    targetFadeAlpha = 1
    ApplyColor(DXD:GetBeaconColor())
    if baseFrame and baseFrame.icon then
        SetObjectiveIcon(baseFrame.icon, DXD.state.targetType)
    end
end

function Beacon:Hide()
    isVisible = false
    targetFadeAlpha = 0
    beamMaskScale = 0
    HideAll()
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
    shimmerTime = 0

    local state = DXD.state
    local sx, sy = GetTargetScreenInfo(state)
    if sx and sy then
        edgeSmoothedX, edgeSmoothedY = sx, sy
    end

    ApplyColor(DXD:GetBeaconColor())
end

function Beacon:OnTargetCleared()
    self:Hide()
    Anim:Reset()
end

------------------------------------------------------------------------
-- MAIN UPDATE
------------------------------------------------------------------------

function Beacon:OnUpdate(elapsed)
    if not isVisible or not DXD.state.hasTarget then return end
    lastElapsed = elapsed
    shimmerTime = shimmerTime + elapsed

    local state = DXD.state

    Anim:UpdateMorph(state.distance3D, elapsed)
    Anim:UpdateIdleFade(state.playerMoving, elapsed)

    local screenX, screenY, onScreen, relBearing = GetTargetScreenInfo(state)
    if not screenX or not screenY then
        HideAll()
        return
    end

    ApplyColor(DXD:GetBeaconColor())

    if onScreen then
        -- Show beam + diamond base, hide edge indicator
        if edgeFrame then edgeFrame:Hide() end
        UpdateBeamAndBase(screenX, screenY, state.distance3D)
    else
        -- Show edge indicator, hide beam
        if beamFrame    then beamFrame:Hide() end
        if baseFrame    then baseFrame:Hide() end
        if fireflyFrame then fireflyFrame:Hide() end
        if elevBadge    then elevBadge:Hide() end
        for _, cf in ipairs(chevronFrames) do cf:Hide() end

        -- Fade for edge indicator
        local fd = targetFadeAlpha - fadeAlpha
        if math_abs(fd) > 0.005 then
            local sp = fd > 0 and (1/Config.ANIMATION.BEACON_FADE_IN) or (1/Config.ANIMATION.BEACON_FADE_OUT)
            fadeAlpha = fadeAlpha + fd * math_min(1, sp * lastElapsed)
        else
            fadeAlpha = targetFadeAlpha
        end

        local idleA = math_max(0.45, Anim:GetIdleAlpha())
        local userOp = DXD.db and DXD.db.beamOpacity or 0.90
        UpdateEdgeIndicator(screenX, screenY, relBearing, state.distance3D, fadeAlpha * userOp * idleA)
    end
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function Beacon:Initialize()
    Anim = DXD:GetModule("BeaconAnimations")

    CreateBeamFrame()
    CreateBaseFrame()
    CreateEdgeIndicator()
    CreateFireflyFrame()
    CreateElevBadge()
    CreateChevrons()

    edgeSmoothedX = GetScreenWidth()  / 2
    edgeSmoothedY = GetScreenHeight() / 2

    DXD:Debug("Beacon initialized (WaypointUI-style)")
end
