------------------------------------------------------------------------
-- DestinationXD - ElevationHUD.lua
-- On-screen elevation indicator: UP/DOWN/LEVEL with decomposed distance
-- Radical minimalism: floating text, no panels, no borders
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local ElevationHUD = {}
DXD:RegisterModule("ElevationHUD", ElevationHUD)

local Utils = DXD.Utils
local Config = DXD.Config

-- Update accumulator
local updateAccum

-- HUD frames
local hudFrame
local elevLine     -- "▲ 34" or "▼ 18" or "═ Level"
local horizLine    -- "→ 52"
local elevIcon     -- The arrow icon texture

-- Animation state
local currentElevColor = Config.COLORS.ELEV_LEVEL
local targetElevColor = Config.COLORS.ELEV_LEVEL
local colorLerpProgress = 1
local currentAlpha = 0
local targetAlpha = 0
local lastElevState = "level"

------------------------------------------------------------------------
-- FRAME CREATION
------------------------------------------------------------------------

local function CreateHUD()
    hudFrame = CreateFrame("Frame", "DXDElevationHUD", UIParent)
    hudFrame:SetSize(120, 50)
    hudFrame:SetFrameStrata("HIGH")
    hudFrame:SetFrameLevel(10)

    -- Position from saved settings
    local anchor = DXD.db.hudAnchor
    hudFrame:SetPoint(anchor.point, UIParent, anchor.relativePoint, anchor.x, anchor.y)

    -- Make draggable (with shift)
    hudFrame:SetMovable(true)
    hudFrame:EnableMouse(false)
    hudFrame:RegisterForDrag("LeftButton")
    hudFrame:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then
            self:StartMoving()
        end
    end)
    hudFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, _, relPoint, x, y = self:GetPoint()
        DXD.db.hudAnchor.point = point
        DXD.db.hudAnchor.relativePoint = relPoint
        DXD.db.hudAnchor.x = x
        DXD.db.hudAnchor.y = y
    end)

    -- Elevation line: "▲ 34" (primary info)
    elevLine = hudFrame:CreateFontString(nil, "OVERLAY")
    elevLine:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.DISTANCE_PRIMARY, "OUTLINE")
    elevLine:SetShadowColor(0, 0, 0, 0.5)
    elevLine:SetShadowOffset(1, -1)
    elevLine:SetPoint("RIGHT", hudFrame, "RIGHT", 0, 8)
    elevLine:SetJustifyH("RIGHT")

    -- Horizontal distance line: "→ 52" (secondary info)
    horizLine = hudFrame:CreateFontString(nil, "OVERLAY")
    horizLine:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.ELEVATION_VALUE, "OUTLINE")
    horizLine:SetShadowColor(0, 0, 0, 0.5)
    horizLine:SetShadowOffset(1, -1)
    horizLine:SetPoint("TOPRIGHT", elevLine, "BOTTOMRIGHT", 0, -4)
    horizLine:SetJustifyH("RIGHT")

    local secondaryColor = Config.COLORS.TEXT_SECONDARY
    horizLine:SetTextColor(secondaryColor.r, secondaryColor.g, secondaryColor.b, secondaryColor.a)

    hudFrame:SetAlpha(0)
    hudFrame:Hide()
end

------------------------------------------------------------------------
-- UPDATE DISPLAY
------------------------------------------------------------------------

local function UpdateDisplay()
    local state = DXD.state

    if not state.hasTarget or not DXD.db.showElevation then
        targetAlpha = 0
        return
    end

    targetAlpha = 1

    local elevState = state.elevationState
    local elevDelta = state.elevationDelta
    local horizDist = state.distanceHorizontal
    local vertDist = state.distanceVertical

    -- Determine color based on elevation state
    local newColor
    if elevState == "above" then
        newColor = Config.COLORS.ELEV_ABOVE
    elseif elevState == "below" then
        newColor = Config.COLORS.ELEV_BELOW
    else
        newColor = Config.COLORS.ELEV_LEVEL
    end

    -- Trigger color transition on state change
    if elevState ~= lastElevState then
        currentElevColor = Utils.DeepCopy(targetElevColor)
        targetElevColor = newColor
        colorLerpProgress = 0
        lastElevState = elevState
    end

    -- Update elevation line text
    if elevState == "above" then
        local vertStr = math.floor(vertDist + 0.5)
        elevLine:SetText("^ " .. vertStr)
    elseif elevState == "below" then
        local vertStr = math.floor(vertDist + 0.5)
        elevLine:SetText("v " .. vertStr)
    else
        local distStr = math.floor(horizDist + 0.5)
        elevLine:SetText("-> " .. distStr)
    end

    -- Update horizontal distance line (only shown when elevation differs)
    if DXD.db.showDecomposedDistance and elevState ~= "level" then
        local horizStr = math.floor(horizDist + 0.5)
        horizLine:SetText("-> " .. horizStr)
        horizLine:Show()
    else
        horizLine:Hide()
    end

    -- Apply interpolated color to elevation line
    if colorLerpProgress < 1 then
        local displayColor = Utils.LerpColor(currentElevColor, targetElevColor, colorLerpProgress)
        elevLine:SetTextColor(displayColor.r, displayColor.g, displayColor.b, displayColor.a)
    else
        elevLine:SetTextColor(targetElevColor.r, targetElevColor.g, targetElevColor.b, targetElevColor.a)
    end
end

------------------------------------------------------------------------
-- PUBLIC API
------------------------------------------------------------------------

function ElevationHUD:OnTargetChanged()
    if hudFrame then
        hudFrame:Show()
        targetAlpha = 1
    end
end

function ElevationHUD:OnTargetCleared()
    targetAlpha = 0
end

------------------------------------------------------------------------
-- UPDATE
------------------------------------------------------------------------

function ElevationHUD:OnUpdate(elapsed)
    if not hudFrame then return end
    if not updateAccum then return end
    if not updateAccum:ShouldUpdate(elapsed) then return end

    UpdateDisplay()

    -- Animate color transition
    if colorLerpProgress < 1 then
        colorLerpProgress = math.min(1, colorLerpProgress + elapsed / Config.ANIMATION.ELEVATION_FADE)
    end

    -- Animate alpha
    local fadeSpeed = elapsed / (targetAlpha > currentAlpha and Config.ANIMATION.HUD_FADE_IN or Config.ANIMATION.HUD_FADE_OUT)
    if currentAlpha < targetAlpha then
        currentAlpha = math.min(currentAlpha + fadeSpeed, targetAlpha)
    elseif currentAlpha > targetAlpha then
        currentAlpha = math.max(currentAlpha - fadeSpeed, targetAlpha)
    end

    -- Apply idle fade
    local Anim = DXD:GetModule("BeaconAnimations")
    local idleAlpha = Anim and Anim:GetIdleAlpha() or 1
    hudFrame:SetAlpha(currentAlpha * idleAlpha)

    if currentAlpha <= 0.01 then
        hudFrame:Hide()
    else
        hudFrame:Show()
    end
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function ElevationHUD:Initialize()
    updateAccum = Utils.CreateAccumulator(Config.UPDATE_RATES.DISTANCE)
    CreateHUD()
    DXD:Debug("ElevationHUD initialized")
end
