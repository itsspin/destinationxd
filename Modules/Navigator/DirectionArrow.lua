------------------------------------------------------------------------
-- DestinationXD - DirectionArrow.lua
-- 3D-aware directional arrow with pitch for elevation
-- Design: thin chevron ∧, floating, no compass rose, no circle
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local DirectionArrow = {}
DXD:RegisterModule("DirectionArrow", DirectionArrow)

local Utils = DXD.Utils
local Config = DXD.Config

-- Update accumulator
local updateAccum

-- Arrow frames
local arrowFrame
local arrowTexture
local distanceText
local etaText

-- Smooth rotation state
local currentRotation = 0
local currentPitch = 0
local currentAlpha = 0
local targetAlpha = 0

------------------------------------------------------------------------
-- FRAME CREATION
------------------------------------------------------------------------

local function CreateArrow()
    arrowFrame = CreateFrame("Frame", "DXDDirectionArrow", UIParent)
    local size = Config.NAVIGATOR.ARROW_SIZE * (DXD.db.arrowScale or 1)
    arrowFrame:SetSize(size, size)
    arrowFrame:SetFrameStrata("HIGH")
    arrowFrame:SetFrameLevel(15)

    -- Position from saved settings
    local anchor = DXD.db.arrowAnchor
    arrowFrame:SetPoint(anchor.point, UIParent, anchor.relativePoint, anchor.x, anchor.y)

    -- Make draggable with shift
    arrowFrame:SetMovable(true)
    arrowFrame:EnableMouse(false)
    arrowFrame:RegisterForDrag("LeftButton")
    arrowFrame:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then
            self:StartMoving()
        end
    end)
    arrowFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        DXD.db.arrowAnchor.point = point
        DXD.db.arrowAnchor.relativePoint = relPoint
        DXD.db.arrowAnchor.x = x
        DXD.db.arrowAnchor.y = y
    end)

    -- Arrow texture (thin chevron ∧)
    -- We use a simple triangle/chevron texture
    arrowTexture = arrowFrame:CreateTexture(nil, "ARTWORK")
    arrowTexture:SetTexture("Interface\\MINIMAP\\ROTATING-MINIMAPGROUPARROW")
    arrowTexture:SetSize(size, size)
    arrowTexture:SetPoint("CENTER")
    arrowTexture:SetBlendMode("ADD")

    local primary = Config.COLORS.TEXT_PRIMARY
    arrowTexture:SetVertexColor(primary.r, primary.g, primary.b, Config.NAVIGATOR.ARROW_ALPHA)

    -- Distance text below arrow
    distanceText = arrowFrame:CreateFontString(nil, "OVERLAY")
    distanceText:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.DISTANCE_PRIMARY, "OUTLINE")
    distanceText:SetShadowColor(0, 0, 0, 0.5)
    distanceText:SetShadowOffset(1, -1)
    distanceText:SetPoint("TOP", arrowFrame, "BOTTOM", 0, -4)
    distanceText:SetJustifyH("CENTER")
    distanceText:SetTextColor(primary.r, primary.g, primary.b, primary.a)

    -- ETA text (smaller, below distance)
    etaText = arrowFrame:CreateFontString(nil, "OVERLAY")
    etaText:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.LABEL, "OUTLINE")
    etaText:SetShadowColor(0, 0, 0, 0.5)
    etaText:SetShadowOffset(1, -1)
    etaText:SetPoint("TOP", distanceText, "BOTTOM", 0, -2)
    etaText:SetJustifyH("CENTER")

    local tertiary = Config.COLORS.TEXT_TERTIARY
    etaText:SetTextColor(tertiary.r, tertiary.g, tertiary.b, tertiary.a)

    arrowFrame:SetAlpha(0)
    arrowFrame:Hide()
end

------------------------------------------------------------------------
-- ARROW ROTATION
------------------------------------------------------------------------

local function UpdateArrowRotation(elapsed)
    local state = DXD.state
    if not state.hasTarget then return end

    -- Target bearing (world direction to target)
    local targetBearing = state.bearing

    -- Player facing direction
    local facing = state.playerFacing

    -- Relative angle: where the target is relative to where we're looking
    local relAngle = targetBearing - facing
    relAngle = Utils.NormalizeAngle(relAngle)

    -- Smooth rotation using lerp
    local lerpFactor = Config.ANIMATION.ARROW_LERP_FACTOR
    local angleDelta = Utils.AngleDelta(currentRotation, relAngle)
    currentRotation = currentRotation + angleDelta * lerpFactor
    currentRotation = Utils.NormalizeAngle(currentRotation)

    -- Apply rotation to texture
    if arrowTexture then
        arrowTexture:SetRotation(-currentRotation)  -- WoW rotation is counter-clockwise
    end

    -- Check if target is behind (for alpha bump)
    local behindThreshold = math.pi * 0.75  -- ~135 degrees
    local isBehind = math.abs(angleDelta) > behindThreshold
    if isBehind then
        arrowTexture:SetAlpha(Config.NAVIGATOR.BEHIND_ALPHA_BUMP)
    else
        arrowTexture:SetAlpha(Config.NAVIGATOR.ARROW_ALPHA)
    end

    -- Pitch component (tilt based on elevation)
    local elevDelta = state.elevationDelta
    local maxPitch = Config.NAVIGATOR.MAX_PITCH_DEGREES * (math.pi / 180)
    local targetPitch = 0

    if state.elevationState == "above" then
        targetPitch = Utils.Clamp(elevDelta / 50, 0, 1) * maxPitch
    elseif state.elevationState == "below" then
        targetPitch = Utils.Clamp(elevDelta / 50, -1, 0) * maxPitch
    end

    -- Smooth pitch
    currentPitch = currentPitch + (targetPitch - currentPitch) * Config.ANIMATION.ARROW_PITCH_LERP

    -- Apply pitch by scaling the vertical axis (WoW doesn't support true 3D rotation on textures)
    -- We simulate pitch by squishing the texture vertically
    local pitchScale = math.cos(currentPitch)
    local size = Config.NAVIGATOR.ARROW_SIZE * (DXD.db.arrowScale or 1)
    if arrowTexture then
        arrowTexture:SetSize(size, size * math.max(0.5, pitchScale))
    end

    -- Color matches beacon
    local beaconColor = DXD:GetBeaconColor()
    if beaconColor and arrowTexture then
        arrowTexture:SetVertexColor(beaconColor.r, beaconColor.g, beaconColor.b)
    end
end

------------------------------------------------------------------------
-- DISTANCE AND ETA DISPLAY
------------------------------------------------------------------------

local function UpdateDistanceDisplay()
    local state = DXD.state
    if not state.hasTarget then return end

    -- Distance text
    local dist = state.distance3D
    if distanceText then
        distanceText:SetText(Utils.FormatDistance(dist))
    end

    -- ETA text
    if DXD.db.showETA and etaText then
        local eta = Utils.EstimateETA(dist)
        if eta then
            etaText:SetText(Utils.FormatETA(eta))
            etaText:Show()
        else
            etaText:Hide()
        end
    elseif etaText then
        etaText:Hide()
    end
end

------------------------------------------------------------------------
-- PUBLIC API
------------------------------------------------------------------------

function DirectionArrow:OnTargetChanged()
    if arrowFrame then
        arrowFrame:Show()
        targetAlpha = 1
    end
end

function DirectionArrow:OnTargetCleared()
    targetAlpha = 0
end

------------------------------------------------------------------------
-- UPDATE
------------------------------------------------------------------------

function DirectionArrow:OnUpdate(elapsed)
    if not arrowFrame then return end
    if not updateAccum then return end
    if not DXD.db.showArrow then
        arrowFrame:Hide()
        return
    end

    if not updateAccum:ShouldUpdate(elapsed) then return end

    if DXD.state.hasTarget then
        targetAlpha = 1
    else
        targetAlpha = 0
    end

    UpdateArrowRotation(elapsed)
    UpdateDistanceDisplay()

    -- Alpha animation
    local fadeSpeed = elapsed / (targetAlpha > currentAlpha and Config.ANIMATION.HUD_FADE_IN or Config.ANIMATION.HUD_FADE_OUT)
    if currentAlpha < targetAlpha then
        currentAlpha = math.min(currentAlpha + fadeSpeed, targetAlpha)
    elseif currentAlpha > targetAlpha then
        currentAlpha = math.max(currentAlpha - fadeSpeed, targetAlpha)
    end

    -- Apply idle fade
    local Anim = DXD:GetModule("BeaconAnimations")
    local idleAlpha = Anim and Anim:GetIdleAlpha() or 1

    arrowFrame:SetAlpha(currentAlpha * idleAlpha)

    if currentAlpha <= 0.01 then
        arrowFrame:Hide()
    else
        arrowFrame:Show()
    end
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function DirectionArrow:Initialize()
    updateAccum = Utils.CreateAccumulator(Config.UPDATE_RATES.ARROW)
    CreateArrow()
    DXD:Debug("DirectionArrow initialized")
end
