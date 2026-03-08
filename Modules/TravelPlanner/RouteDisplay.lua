------------------------------------------------------------------------
-- DestinationXD - RouteDisplay.lua
-- Step-by-step route visualization for Travel Planner
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local RouteDisplay = {}
DXD:RegisterModule("RouteDisplay", RouteDisplay)

local Utils = DXD.Utils
local Config = DXD.Config

-- Circled number characters for step numbering
local CIRCLED_NUMBERS = {
    "\226\145\160", -- ①
    "\226\145\161", -- ②
    "\226\145\162", -- ③
    "\226\145\163", -- ④
    "\226\145\164", -- ⑤
    "\226\145\165", -- ⑥
    "\226\145\166", -- ⑦
    "\226\145\167", -- ⑧
    "\226\145\168", -- ⑨
    "\226\145\169", -- ⑩
}

--- Get the circled number for a step index
function RouteDisplay:GetStepNumber(index)
    return CIRCLED_NUMBERS[index] or tostring(index)
end

--- Format a route step for display
function RouteDisplay:FormatStep(step, index)
    if not step then return "" end

    local planner = DXD:GetModule("TravelPlanner")
    local icon = planner and planner:GetMethodIcon(step.method) or ""
    local num = self:GetStepNumber(index)

    local text = num .. " " .. icon .. " " .. (step.name or "Travel")
    if step.zoneName then
        text = text .. " \226\134\146 " .. step.zoneName  -- →
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
