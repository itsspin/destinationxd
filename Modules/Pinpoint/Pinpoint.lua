------------------------------------------------------------------------
-- DestinationXD - Pinpoint.lua
-- In-world floating quest/waypoint info display
-- Design: no background, no border, just text with shadow
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local Pinpoint = {}
DXD:RegisterModule("Pinpoint", Pinpoint)

local Utils = DXD.Utils
local Config = DXD.Config
local Formatting = DXD:GetModule("PinpointFormatting")

-- Update accumulator
local updateAccum

-- Frames
local pinpointFrame
local titleText
local subtitleText
local infoText
local labelText

-- State
local currentAlpha = 0
local targetAlpha = 0

------------------------------------------------------------------------
-- FRAME CREATION
------------------------------------------------------------------------

local function CreatePinpoint()
    pinpointFrame = CreateFrame("Frame", "DXDPinpoint", UIParent)
    pinpointFrame:SetSize(200, 60)
    pinpointFrame:SetFrameStrata("HIGH")
    pinpointFrame:SetFrameLevel(12)
    pinpointFrame:Hide()

    -- Title: quest/waypoint name (primary)
    titleText = pinpointFrame:CreateFontString(nil, "OVERLAY")
    titleText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    titleText:SetShadowColor(0, 0, 0, 0.5)
    titleText:SetShadowOffset(1, -1)
    titleText:SetPoint("TOP", pinpointFrame, "TOP", 0, 0)
    titleText:SetJustifyH("CENTER")
    titleText:SetWidth(200)
    titleText:SetWordWrap(true)
    local primary = Config.COLORS.TEXT_PRIMARY
    titleText:SetTextColor(primary.r, primary.g, primary.b, primary.a)

    -- Subtitle: objective text (secondary)
    subtitleText = pinpointFrame:CreateFontString(nil, "OVERLAY")
    subtitleText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    subtitleText:SetShadowColor(0, 0, 0, 0.5)
    subtitleText:SetShadowOffset(1, -1)
    subtitleText:SetPoint("TOP", titleText, "BOTTOM", 0, -2)
    subtitleText:SetJustifyH("CENTER")
    subtitleText:SetWidth(200)
    subtitleText:SetWordWrap(true)
    local secondary = Config.COLORS.TEXT_SECONDARY
    subtitleText:SetTextColor(secondary.r, secondary.g, secondary.b, secondary.a)

    -- Info line: distance + ETA
    infoText = pinpointFrame:CreateFontString(nil, "OVERLAY")
    infoText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    infoText:SetShadowColor(0, 0, 0, 0.5)
    infoText:SetShadowOffset(1, -1)
    infoText:SetPoint("TOP", subtitleText, "BOTTOM", 0, -2)
    infoText:SetJustifyH("CENTER")
    local tertiary = Config.COLORS.TEXT_TERTIARY
    infoText:SetTextColor(tertiary.r, tertiary.g, tertiary.b, tertiary.a)

    -- Type label (tiny, whisper-quiet)
    labelText = pinpointFrame:CreateFontString(nil, "OVERLAY")
    labelText:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.LABEL, "OUTLINE")
    labelText:SetShadowColor(0, 0, 0, 0.5)
    labelText:SetShadowOffset(1, -1)
    labelText:SetPoint("TOP", infoText, "BOTTOM", 0, -1)
    labelText:SetJustifyH("CENTER")
    labelText:SetTextColor(tertiary.r, tertiary.g, tertiary.b, tertiary.a * 0.7)
end

------------------------------------------------------------------------
-- POSITIONING
------------------------------------------------------------------------

local function UpdatePinpointPosition()
    local state = DXD.state
    if not state.hasTarget then return end

    local targetX = state.targetWorldX
    local targetY = state.targetWorldY
    local targetZ = (state.targetWorldZ or 0) + 3  -- Slightly above beacon point

    local screenX, screenY, onScreen = Utils.WorldToScreen(targetX, targetY, targetZ)

    if onScreen and screenX and screenY then
        -- Position above the beacon
        pinpointFrame:ClearAllPoints()
        pinpointFrame:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", screenX, screenY + 20)
        targetAlpha = 1

        -- Distance-based alpha: full at 20-50y, fade beyond 80y
        local dist = state.distance3D
        if dist then
            if dist > 80 then
                targetAlpha = 0
            elseif dist > 50 then
                targetAlpha = Utils.Remap(dist, 50, 80, 1, 0)
            end
            -- Also scale with distance (larger text when far would be bad)
            local scale = Utils.Clamp(Utils.Remap(dist, 20, 100, 1, 0.7), 0.7, 1)
            pinpointFrame:SetScale(scale)
        end

        -- Camera facing check: fade when not looking at it
        local facing = state.playerFacing
        local bearing = state.bearing
        if facing and bearing then
            local faceDelta = math.abs(Utils.AngleDelta(facing, bearing))
            if faceDelta > math.pi * 0.6 then
                targetAlpha = targetAlpha * 0.3
            end
        end
    else
        targetAlpha = 0
    end
end

------------------------------------------------------------------------
-- PUBLIC API
------------------------------------------------------------------------

function Pinpoint:OnTargetChanged()
    if pinpointFrame then
        pinpointFrame:Show()
        targetAlpha = 1
    end
end

function Pinpoint:OnTargetCleared()
    targetAlpha = 0
end

------------------------------------------------------------------------
-- UPDATE
------------------------------------------------------------------------

function Pinpoint:OnUpdate(elapsed)
    if not pinpointFrame then return end
    if not updateAccum then return end
    if not updateAccum:ShouldUpdate(elapsed) then return end

    if not DXD.state.hasTarget then
        targetAlpha = 0
    end

    -- Update text content
    if Formatting then
        local title = Formatting:GetTitle()
        local subtitle = Formatting:GetSubtitle()
        local info = Formatting:GetInfoLine()
        local label = Formatting:GetTypeLabel()

        if titleText then titleText:SetText(title or "") end
        if subtitleText then
            if subtitle then
                subtitleText:SetText(subtitle)
                subtitleText:Show()
            else
                subtitleText:Hide()
            end
        end
        if infoText then infoText:SetText(info or "") end
        if labelText then
            labelText:SetText(label)
            local labelColor = Formatting:GetTypeLabelColor()
            if labelColor then
                labelText:SetTextColor(labelColor.r, labelColor.g, labelColor.b, 0.35)
            end
        end
    end

    -- Update position
    UpdatePinpointPosition()

    -- Animate alpha
    local speed = elapsed / (targetAlpha > currentAlpha and Config.ANIMATION.HUD_FADE_IN or Config.ANIMATION.HUD_FADE_OUT)
    if currentAlpha < targetAlpha then
        currentAlpha = math.min(currentAlpha + speed, targetAlpha)
    elseif currentAlpha > targetAlpha then
        currentAlpha = math.max(currentAlpha - speed, targetAlpha)
    end

    -- Apply idle fade
    local Anim = DXD:GetModule("BeaconAnimations")
    local idleAlpha = Anim and Anim:GetIdleAlpha() or 1

    pinpointFrame:SetAlpha(currentAlpha * idleAlpha)

    if currentAlpha <= 0.01 then
        pinpointFrame:Hide()
    else
        pinpointFrame:Show()
    end
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function Pinpoint:Initialize()
    updateAccum = Utils.CreateAccumulator(Config.UPDATE_RATES.DISTANCE)
    CreatePinpoint()
    DXD:Debug("Pinpoint initialized")
end
