------------------------------------------------------------------------
-- DestinationXD - RouteDisplay.lua
-- Step-by-step route visualization for Travel Planner
-- Uses only ASCII + WoW color codes (no Unicode that might render as [])
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local RouteDisplay = {}
DXD:RegisterModule("RouteDisplay", RouteDisplay)

local Utils = DXD.Utils
local Config = DXD.Config

--- Format a route step for display
function RouteDisplay:FormatStep(step, index)
    if not step then return "" end

    local planner = DXD:GetModule("TravelPlanner")
    local icon = planner and planner:GetMethodIcon(step.method) or ""

    -- Plain number with color (no Unicode circled digits)
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

function RouteDisplay:Initialize()
    DXD:Debug("RouteDisplay initialized")
end
