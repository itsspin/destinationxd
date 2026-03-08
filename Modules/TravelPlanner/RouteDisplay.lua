------------------------------------------------------------------------
-- DestinationXD - RouteDisplay.lua
-- Step-by-step route visualization for Travel Planner
-- Also provides a persistent on-screen route tracker panel during
-- active navigation that shows all steps with the current one highlighted.
-- Uses only ASCII + WoW color codes (no Unicode that might render as [])
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local RouteDisplay = {}
DXD:RegisterModule("RouteDisplay", RouteDisplay)

local Utils = DXD.Utils
local Config = DXD.Config

-- On-screen route tracker
local routeTracker
local stepLines = {}

------------------------------------------------------------------------
-- STEP FORMATTING
------------------------------------------------------------------------

--- Format a route step for display
function RouteDisplay:FormatStep(step, index)
    if not step then return "" end

    local planner = DXD:GetModule("TravelPlanner")
    local icon = planner and planner:GetMethodIcon(step.method) or ""

    local num = "|cff66d9ef" .. tostring(index) .. ".|r"

    local text = num .. " " .. icon .. " " .. (step.name or "Travel")
    if step.zoneName then
        text = text .. " |cff888888->|r " .. step.zoneName
    end

    return text
end

--- Format the total time estimate
function RouteDisplay:FormatTotalTime(route)
    if not route then return "" end
    return Utils.FormatETA(route.totalCost or 0)
end

--- Get the current step highlight index
function RouteDisplay:GetCurrentStep()
    local planner = DXD:GetModule("TravelPlanner")
    if planner then
        local route, step = planner:GetCurrentRoute()
        return step
    end
    return 0
end

------------------------------------------------------------------------
-- ON-SCREEN ROUTE TRACKER PANEL
------------------------------------------------------------------------

local function CreateRouteTracker()
    routeTracker = CreateFrame("Frame", "DXDRouteTracker", UIParent, "BackdropTemplate")
    routeTracker:SetSize(260, 60)
    routeTracker:SetPoint("RIGHT", UIParent, "RIGHT", -20, 100)
    routeTracker:SetFrameStrata("MEDIUM")
    routeTracker:SetFrameLevel(10)

    routeTracker:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    local bg = Config.COLORS.PANEL_BG
    routeTracker:SetBackdropColor(bg.r, bg.g, bg.b, 0.70)
    routeTracker:SetBackdropBorderColor(1, 1, 1, 0.06)

    routeTracker:SetMovable(true)
    routeTracker:EnableMouse(true)
    routeTracker:RegisterForDrag("LeftButton")
    routeTracker:SetScript("OnDragStart", routeTracker.StartMoving)
    routeTracker:SetScript("OnDragStop", routeTracker.StopMovingOrSizing)
    routeTracker:SetClampedToScreen(true)

    -- Title
    routeTracker.title = routeTracker:CreateFontString(nil, "OVERLAY")
    routeTracker.title:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    routeTracker.title:SetShadowColor(0, 0, 0, 0.5)
    routeTracker.title:SetShadowOffset(1, -1)
    routeTracker.title:SetPoint("TOPLEFT", 8, -6)
    local tertiary = Config.COLORS.TEXT_TERTIARY
    routeTracker.title:SetTextColor(tertiary.r, tertiary.g, tertiary.b, 0.5)
    routeTracker.title:SetText("ROUTE")

    -- Cancel button
    routeTracker.cancelBtn = CreateFrame("Button", nil, routeTracker)
    routeTracker.cancelBtn:SetSize(16, 16)
    routeTracker.cancelBtn:SetPoint("TOPRIGHT", -4, -4)
    local cancelText = routeTracker.cancelBtn:CreateFontString(nil, "OVERLAY")
    cancelText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    cancelText:SetShadowColor(0, 0, 0, 0.5)
    cancelText:SetShadowOffset(1, -1)
    cancelText:SetPoint("CENTER")
    cancelText:SetText("|cff666670x|r")
    routeTracker.cancelBtn:SetScript("OnClick", function()
        local planner = DXD:GetModule("TravelPlanner")
        if planner then planner:CancelRoute() end
    end)
    routeTracker.cancelBtn:SetScript("OnEnter", function()
        cancelText:SetText("|cffff4444x|r")
    end)
    routeTracker.cancelBtn:SetScript("OnLeave", function()
        cancelText:SetText("|cff666670x|r")
    end)

    routeTracker:Hide()
end

--- Update the route tracker panel with current route state
function RouteDisplay:UpdateTracker()
    if not routeTracker then return end

    local planner = DXD:GetModule("TravelPlanner")
    if not planner then
        routeTracker:Hide()
        return
    end

    local route, currentStep = planner:GetCurrentRoute()
    if not route or not route.steps or #route.steps == 0 then
        routeTracker:Hide()
        return
    end

    -- Clear old step lines
    for _, line in ipairs(stepLines) do
        line:Hide()
    end

    local yOffset = -20
    local primary = Config.COLORS.TEXT_PRIMARY
    local secondary = Config.COLORS.TEXT_SECONDARY
    local tertiary = Config.COLORS.TEXT_TERTIARY

    for i, step in ipairs(route.steps) do
        if not stepLines[i] then
            stepLines[i] = routeTracker:CreateFontString(nil, "OVERLAY")
            stepLines[i]:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            stepLines[i]:SetShadowColor(0, 0, 0, 0.5)
            stepLines[i]:SetShadowOffset(1, -1)
            stepLines[i]:SetWidth(240)
            stepLines[i]:SetJustifyH("LEFT")
            stepLines[i]:SetWordWrap(false)
        end

        local line = stepLines[i]
        line:SetPoint("TOPLEFT", 8, yOffset)

        local icon = planner:GetMethodIcon(step.method) or ""
        local stepName = step.name or "Travel"

        if i == currentStep then
            -- Current step: bright, with arrow indicator
            line:SetText("|cff66d9ef>>|r " .. icon .. " " .. stepName)
            line:SetTextColor(primary.r, primary.g, primary.b, 0.95)
        elseif i < currentStep then
            -- Completed step: dimmed with checkmark
            line:SetText("|cff44aa44+|r " .. stepName)
            line:SetTextColor(tertiary.r, tertiary.g, tertiary.b, 0.35)
        else
            -- Future step
            line:SetText("  " .. icon .. " " .. stepName)
            line:SetTextColor(secondary.r, secondary.g, secondary.b, 0.55)
        end

        line:Show()
        yOffset = yOffset - 16
    end

    -- Resize panel to fit
    routeTracker:SetHeight(math.abs(yOffset) + 10)
    routeTracker:Show()
end

function RouteDisplay:HideTracker()
    if routeTracker then routeTracker:Hide() end
end

function RouteDisplay:OnTargetChanged()
    self:UpdateTracker()
end

function RouteDisplay:OnTargetCleared()
    -- Only hide if no active route
    local planner = DXD:GetModule("TravelPlanner")
    if planner then
        local route = planner:GetCurrentRoute()
        if not route then
            self:HideTracker()
        end
    end
end

function RouteDisplay:OnUpdate(elapsed)
    -- Refresh tracker periodically while a route is active
    if not routeTracker or not routeTracker:IsShown() then return end
    self:UpdateTracker()
end

function RouteDisplay:Initialize()
    CreateRouteTracker()
    DXD:Debug("RouteDisplay initialized")
end
