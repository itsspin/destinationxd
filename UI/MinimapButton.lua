------------------------------------------------------------------------
-- DestinationXD - MinimapButton.lua
-- Clean minimap icon using LibDBIcon
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local MinimapButton = {}
DXD:RegisterModule("MinimapButton", MinimapButton)

local Config = DXD.Config

-- The data broker object
local dataBroker

-- Active navigation indicator dot
local indicatorDot

------------------------------------------------------------------------
-- CREATION
------------------------------------------------------------------------

local function CreateMinimapButton()
    dataBroker = DXD.LDB:NewDataObject("DestinationXD", {
        type = "launcher",
        text = "DestinationXD",
        icon = "Interface\\MINIMAP\\TRACKING\\None",
        OnClick = function(self, button)
            if button == "LeftButton" then
                -- Toggle Travel Planner
                local tpFrame = DXD:GetModule("TravelPlannerFrame")
                if tpFrame then
                    tpFrame:Toggle()
                elseif DestinationXDTravelFrame then
                    if DestinationXDTravelFrame:IsShown() then
                        DestinationXDTravelFrame:Hide()
                    else
                        DestinationXDTravelFrame:Show()
                    end
                else
                    DXD:Print("Travel Planner is loading...")
                end
            elseif button == "RightButton" then
                -- Quick options menu
                MinimapButton:ShowQuickMenu(self)
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("DestinationXD", 0.92, 0.92, 0.95)

            local state = DXD.state
            if state.hasTarget then
                local dist = DXD.Utils.FormatDistance(state.distance3D)
                local name = state.targetName or "Waypoint"
                if #name > 25 then name = name:sub(1, 22) .. "..." end
                tooltip:AddLine(name .. " - " .. dist, 0.75, 0.75, 0.80)
            end

            tooltip:AddLine(" ")
            tooltip:AddLine("Left-click: Travel Planner", 0.60, 0.60, 0.65)
            tooltip:AddLine("Right-click: Quick menu", 0.60, 0.60, 0.65)
        end,
    })

    -- Register with LibDBIcon
    DXD.LDBIcon:Register("DestinationXD", dataBroker, DXD.db.minimap)
end

------------------------------------------------------------------------
-- ACTIVE INDICATOR DOT
------------------------------------------------------------------------

local function UpdateIndicatorDot()
    local button = DXD.LDBIcon:GetMinimapButton("DestinationXD")
    if not button then return end

    if not indicatorDot then
        indicatorDot = button:CreateTexture(nil, "OVERLAY")
        indicatorDot:SetTexture("Interface\\BUTTONS\\WHITE8X8")
        indicatorDot:SetSize(4, 4)
        indicatorDot:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -6, 6)
        indicatorDot:SetBlendMode("ADD")
    end

    if DXD.state.hasTarget then
        local color = DXD:GetBeaconColor()
        indicatorDot:SetVertexColor(color.r, color.g, color.b, 0.9)
        indicatorDot:Show()
    else
        indicatorDot:Hide()
    end
end

------------------------------------------------------------------------
-- QUICK MENU
------------------------------------------------------------------------

function MinimapButton:ShowQuickMenu(anchorFrame)
    -- Use modern MenuUtil if available (WoW 10.x+), fallback to EasyMenu
    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(anchorFrame, function(ownerRegion, rootDescription)
            rootDescription:CreateTitle("DestinationXD")
            rootDescription:CreateButton("Clear Waypoint", function()
                DXD:ClearTarget()
                DXD:Print("Waypoint cleared.")
            end)
            rootDescription:CreateButton("Toggle Elevation HUD", function()
                DXD.db.showElevation = not DXD.db.showElevation
                DXD:Print("Elevation HUD: " .. (DXD.db.showElevation and "ON" or "OFF"))
            end)
            rootDescription:CreateButton("Toggle Direction Arrow", function()
                DXD.db.showArrow = not DXD.db.showArrow
                DXD:Print("Direction Arrow: " .. (DXD.db.showArrow and "ON" or "OFF"))
            end)
            rootDescription:CreateButton("Settings (/dxd)", function()
                local settings = DXD:GetModule("SettingsPanel")
                if settings then settings:Toggle() end
            end)
        end)
    elseif EasyMenu then
        -- Legacy fallback for older clients
        local menu = {
            { text = "DestinationXD", isTitle = true, notCheckable = true },
            { text = "Clear Waypoint", notCheckable = true, func = function() DXD:ClearTarget(); DXD:Print("Waypoint cleared.") end },
            { text = "Toggle Elevation HUD", notCheckable = true, func = function() DXD.db.showElevation = not DXD.db.showElevation end },
            { text = "Toggle Direction Arrow", notCheckable = true, func = function() DXD.db.showArrow = not DXD.db.showArrow end },
            { text = "Settings (/dxd)", notCheckable = true, func = function() local s = DXD:GetModule("SettingsPanel"); if s then s:Toggle() end end },
            { text = "Cancel", notCheckable = true },
        }
        local menuFrame = CreateFrame("Frame", "DXDMinimapMenu", UIParent, "UIDropDownMenuTemplate")
        EasyMenu(menu, menuFrame, anchorFrame or "cursor", 0, 0, "MENU")
    end
end

------------------------------------------------------------------------
-- PUBLIC API
------------------------------------------------------------------------

function MinimapButton:OnTargetChanged()
    UpdateIndicatorDot()
end

function MinimapButton:OnTargetCleared()
    UpdateIndicatorDot()
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function MinimapButton:Initialize()
    CreateMinimapButton()

    -- Update indicator periodically
    C_Timer.NewTicker(2, UpdateIndicatorDot)

    DXD:Debug("MinimapButton initialized")
end
