------------------------------------------------------------------------
-- DestinationXD - DirectionArrow.lua
-- On-screen navigation HUD: direction arrow, distance, target info,
-- route step guidance. This is the primary user-facing navigation display.
-- Uses bearing-based arrow rotation with smooth lerping.
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local DirectionArrow = {}
DXD:RegisterModule("DirectionArrow", DirectionArrow)

local Utils = DXD.Utils
local Config = DXD.Config

-- Update accumulator
local updateAccum

-- Frames
local hudFrame        -- Main container
local arrowFrame      -- The rotating arrow
local arrowTextures   -- Arrow chevron textures (multiple for a nice look)
local nameText        -- Target name
local distText        -- Distance display
local etaText         -- ETA display
local stepText        -- Current route step instruction
local elevText        -- Elevation indicator

-- Animation state
local currentArrowAngle = 0
local currentAlpha = 0
local targetAlpha = 0

-- Arrow chevron points (drawn with simple triangles)
local ARROW_SIZE = 40
local NUM_CHEVRONS = 3

------------------------------------------------------------------------
-- FRAME CREATION
------------------------------------------------------------------------

local function CreateArrowChevron(parent, size, yOff, alpha)
    -- Use a simple rotatable texture for the arrow
    local tex = parent:CreateTexture(nil, "ARTWORK")
    tex:SetTexture("Interface\\MINIMAP\\ROTATING-MINIMAPGUIDEARROW")
    tex:SetSize(size, size)
    tex:SetPoint("CENTER", 0, yOff)
    tex:SetAlpha(alpha)
    return tex
end

local function CreateHUD()
    -- Main HUD container
    hudFrame = CreateFrame("Frame", "DXDNavigationHUD", UIParent)
    hudFrame:SetSize(300, 140)
    hudFrame:SetFrameStrata("HIGH")
    hudFrame:SetFrameLevel(15)
    hudFrame:SetMovable(true)
    hudFrame:EnableMouse(true)
    hudFrame:RegisterForDrag("LeftButton")
    hudFrame:SetScript("OnDragStart", hudFrame.StartMoving)
    hudFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, _, relPoint, x, y = self:GetPoint()
        if DXD.db then
            DXD.db.arrowAnchor = { point = point, relativePoint = relPoint, x = x, y = y }
        end
    end)
    hudFrame:SetClampedToScreen(true)

    -- Position from saved vars
    local anchor = DXD.db and DXD.db.arrowAnchor
    if anchor then
        hudFrame:SetPoint(anchor.point, UIParent, anchor.relativePoint, anchor.x, anchor.y)
    else
        hudFrame:SetPoint("TOP", UIParent, "TOP", 0, -120)
    end

    -- Arrow container (rotates)
    arrowFrame = CreateFrame("Frame", nil, hudFrame)
    arrowFrame:SetSize(ARROW_SIZE + 10, ARROW_SIZE + 10)
    arrowFrame:SetPoint("TOP", hudFrame, "TOP", 0, 0)

    -- Create arrow texture - use the built-in WoW navigation arrow
    arrowTextures = {}
    local mainArrow = arrowFrame:CreateTexture(nil, "ARTWORK")
    mainArrow:SetTexture("Interface\\MINIMAP\\ROTATING-MINIMAPGUIDEARROW")
    mainArrow:SetSize(ARROW_SIZE, ARROW_SIZE)
    mainArrow:SetPoint("CENTER")
    mainArrow:SetVertexColor(0.4, 0.85, 1.0, 0.9)
    table.insert(arrowTextures, mainArrow)

    -- Glow behind arrow
    local arrowGlow = arrowFrame:CreateTexture(nil, "BACKGROUND")
    arrowGlow:SetTexture("Interface\\MINIMAP\\ROTATING-MINIMAPGUIDEARROW")
    arrowGlow:SetSize(ARROW_SIZE + 12, ARROW_SIZE + 12)
    arrowGlow:SetPoint("CENTER")
    arrowGlow:SetVertexColor(0.4, 0.85, 1.0, 0.15)
    table.insert(arrowTextures, arrowGlow)

    -- Target name
    nameText = hudFrame:CreateFontString(nil, "OVERLAY")
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    nameText:SetShadowColor(0, 0, 0, 0.8)
    nameText:SetShadowOffset(1, -1)
    nameText:SetPoint("TOP", arrowFrame, "BOTTOM", 0, -4)
    nameText:SetJustifyH("CENTER")
    nameText:SetWidth(280)
    nameText:SetWordWrap(false)
    local primary = Config.COLORS.TEXT_PRIMARY
    nameText:SetTextColor(primary.r, primary.g, primary.b, 0.9)

    -- Distance
    distText = hudFrame:CreateFontString(nil, "OVERLAY")
    distText:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    distText:SetShadowColor(0, 0, 0, 0.8)
    distText:SetShadowOffset(1, -1)
    distText:SetPoint("TOP", nameText, "BOTTOM", 0, -2)
    distText:SetJustifyH("CENTER")
    distText:SetTextColor(0.4, 0.85, 1.0, 0.9)

    -- Elevation indicator
    elevText = hudFrame:CreateFontString(nil, "OVERLAY")
    elevText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    elevText:SetShadowColor(0, 0, 0, 0.8)
    elevText:SetShadowOffset(1, -1)
    elevText:SetPoint("TOP", distText, "BOTTOM", 0, -1)
    elevText:SetJustifyH("CENTER")

    -- ETA
    etaText = hudFrame:CreateFontString(nil, "OVERLAY")
    etaText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    etaText:SetShadowColor(0, 0, 0, 0.8)
    etaText:SetShadowOffset(1, -1)
    etaText:SetPoint("TOP", elevText, "BOTTOM", 0, -1)
    etaText:SetJustifyH("CENTER")
    local tertiary = Config.COLORS.TEXT_TERTIARY
    etaText:SetTextColor(tertiary.r, tertiary.g, tertiary.b, 0.6)

    -- Route step instruction
    stepText = hudFrame:CreateFontString(nil, "OVERLAY")
    stepText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    stepText:SetShadowColor(0, 0, 0, 0.8)
    stepText:SetShadowOffset(1, -1)
    stepText:SetPoint("TOP", etaText, "BOTTOM", 0, -4)
    stepText:SetJustifyH("CENTER")
    stepText:SetWidth(280)
    stepText:SetWordWrap(true)
    local secondary = Config.COLORS.TEXT_SECONDARY
    stepText:SetTextColor(secondary.r, secondary.g, secondary.b, 0.7)

    hudFrame:SetAlpha(0)
    hudFrame:Hide()
end

------------------------------------------------------------------------
-- ARROW ROTATION
------------------------------------------------------------------------

local function GetTargetAngle()
    local state = DXD.state
    if not state.hasTarget then return nil end

    local facing = state.playerFacing
    local bearing = state.bearing

    if not facing or not bearing then return nil end

    -- Angle from player facing to target bearing
    -- WoW: facing = 0 north, increases counter-clockwise
    -- We want: arrow rotation where 0 = up (pointing forward)
    local delta = Utils.AngleDelta(facing, bearing)
    return -delta  -- Negate for screen rotation (clockwise positive)
end

local function SetArrowColor(targetType)
    local color = DXD:GetBeaconColor()
    if not color then return end
    for _, tex in ipairs(arrowTextures) do
        if tex == arrowTextures[1] then
            tex:SetVertexColor(color.r, color.g, color.b, color.a or 0.9)
        else
            tex:SetVertexColor(color.r, color.g, color.b, 0.15)
        end
    end
    -- Distance text matches arrow color
    if distText then
        distText:SetTextColor(color.r, color.g, color.b, 0.9)
    end
end

------------------------------------------------------------------------
-- UPDATE
------------------------------------------------------------------------

local function UpdateHUD(elapsed)
    local state = DXD.state
    if not hudFrame then return end

    if not state.hasTarget then
        targetAlpha = 0
    else
        targetAlpha = 1
    end

    -- Animate alpha
    local fadeSpeed = elapsed / (targetAlpha > currentAlpha and 0.2 or 0.4)
    if currentAlpha < targetAlpha then
        currentAlpha = math.min(currentAlpha + fadeSpeed, targetAlpha)
    elseif currentAlpha > targetAlpha then
        currentAlpha = math.max(currentAlpha - fadeSpeed, targetAlpha)
    end

    if currentAlpha <= 0.01 then
        hudFrame:Hide()
        return
    end

    hudFrame:Show()
    hudFrame:SetAlpha(currentAlpha)

    -- Apply scale from settings
    local scale = DXD.db and DXD.db.arrowScale or 1.0
    hudFrame:SetScale(scale)

    -- Rotate arrow toward target
    local targetAngle = GetTargetAngle()
    if targetAngle then
        -- Smooth lerp the angle (handle wrap-around)
        local angleDelta = Utils.AngleDelta(currentArrowAngle, targetAngle)
        local lerpFactor = Config.ANIMATION.ARROW_LERP_FACTOR or 0.35
        currentArrowAngle = currentArrowAngle + angleDelta * math.min(1, lerpFactor * elapsed * 60)

        -- Apply rotation to all arrow textures
        for _, tex in ipairs(arrowTextures) do
            tex:SetRotation(currentArrowAngle)
        end
    end

    -- Update target name
    local name = state.targetName or "Waypoint"
    -- Truncate long names
    if #name > 40 then
        name = name:sub(1, 37) .. "..."
    end
    nameText:SetText(name)

    -- Update distance
    local distInfo = DXD:GetModule("DistanceDisplay")
    if distInfo then
        local info = distInfo:GetFormattedInfo()
        if info then
            distText:SetText(info.total)

            -- Elevation indicator
            if state.elevationState == "above" and state.distanceVertical > 5 then
                local vc = Config.COLORS.ELEV_ABOVE
                elevText:SetText("^ " .. info.vertical .. " above")
                elevText:SetTextColor(vc.r, vc.g, vc.b, 0.8)
                elevText:Show()
            elseif state.elevationState == "below" and state.distanceVertical > 5 then
                local vc = Config.COLORS.ELEV_BELOW
                elevText:SetText("v " .. info.vertical .. " below")
                elevText:SetTextColor(vc.r, vc.g, vc.b, 0.8)
                elevText:Show()
            else
                elevText:Hide()
            end

            -- ETA
            if info.eta and DXD.db and DXD.db.showETA then
                etaText:SetText(info.eta)
                etaText:Show()
            else
                etaText:Hide()
            end
        end
    end

    -- Show route step info if on an active route
    local planner = DXD:GetModule("TravelPlanner")
    if planner then
        local route, stepIdx = planner:GetCurrentRoute()
        if route and route.steps and stepIdx and stepIdx > 0 then
            local step = route.steps[stepIdx]
            if step then
                local stepStr = "|cff66d9efStep " .. stepIdx .. "/" .. #route.steps .. "|r  " .. (step.name or "Travel")
                -- Hearthstone steps get a highlighted instruction
                if step.method == 4 then -- METHOD.HEARTHSTONE
                    stepStr = "|cffff6666USE NOW:|r " .. (step.name or "Hearthstone")
                end
                stepText:SetText(stepStr)
                stepText:Show()
            else
                stepText:Hide()
            end
        else
            -- Show description if available
            if state.targetDescription then
                stepText:SetText(state.targetDescription)
                stepText:Show()
            else
                stepText:Hide()
            end
        end
    end
end

------------------------------------------------------------------------
-- PUBLIC API
------------------------------------------------------------------------

function DirectionArrow:OnTargetChanged()
    if hudFrame then
        targetAlpha = 1
        SetArrowColor(DXD.state.targetType)
    end
end

function DirectionArrow:OnTargetCleared()
    targetAlpha = 0
    if stepText then stepText:SetText("") end
end

function DirectionArrow:OnUpdate(elapsed)
    if not hudFrame then return end
    if not DXD.db or not DXD.db.showArrow then return end
    if not updateAccum then return end
    -- Arrow updates every frame for smooth rotation
    UpdateHUD(elapsed)
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function DirectionArrow:Initialize()
    updateAccum = Utils.CreateAccumulator(0)  -- every frame
    CreateHUD()
    DXD:Debug("DirectionArrow initialized (active)")
end
