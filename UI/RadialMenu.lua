------------------------------------------------------------------------
-- DestinationXD - RadialMenu.lua
-- Quick-access radial/ring menu that appears around the cursor when
-- the user holds the configured hotkey (default: tilde/`).
-- Shows dynamic options: nearby services, recent destinations, M+ dungeons.
-- Designed for fast, one-handed navigation without opening panels.
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local RadialMenu = {}
DXD:RegisterModule("RadialMenu", RadialMenu)

local Config = DXD.Config
local Utils = DXD.Utils

-- Frames
local menuFrame
local menuItems = {}
local centerLabel
local isShowing = false

-- Config
local RING_RADIUS = 100
local ITEM_SIZE = 60
local MAX_ITEMS = 8
local CENTER_SIZE = 50

------------------------------------------------------------------------
-- MENU DATA
------------------------------------------------------------------------

local function GetMenuItems()
    local items = {}

    -- 1. City services if in a city
    local playerMapID = C_Map.GetBestMapForUnit("player")
    local cityMapID = playerMapID

    if cityMapID and DXD.CityMapAliases and DXD.CityMapAliases[cityMapID] then
        cityMapID = DXD.CityMapAliases[cityMapID]
    end
    if cityMapID and DXD.CityServices and not DXD.CityServices[cityMapID] then
        local parentInfo = cityMapID and C_Map.GetMapInfo(cityMapID)
        if parentInfo and parentInfo.parentMapID and parentInfo.parentMapID > 0 then
            local parentID = parentInfo.parentMapID
            if DXD.CityServices[parentID] then
                cityMapID = parentID
            elseif DXD.CityMapAliases and DXD.CityMapAliases[parentID] then
                cityMapID = DXD.CityMapAliases[parentID]
            end
        end
    end

    local cityData = cityMapID and DXD.CityServices and DXD.CityServices[cityMapID]
    if cityData then
        -- Show top services: AH, Bank, Flight Master, Portal, Repair, Inn
        local priority = { "auction", "bank", "flight", "portal", "repair", "inn", "mail", "transmog" }
        for _, svcType in ipairs(priority) do
            if #items >= MAX_ITEMS then break end
            for _, svc in ipairs(cityData.services) do
                if svc.type == svcType then
                    local svcInfo = DXD.ServiceIcons and DXD.ServiceIcons[svc.type]
                    local color = svcInfo and svcInfo.color or { r = 0.5, g = 0.85, b = 1.0 }
                    table.insert(items, {
                        label = svc.name,
                        shortLabel = svcInfo and svcInfo.label or svc.name,
                        color = color,
                        action = function()
                            DXD:SetTarget(cityMapID, svc.x, svc.y, "waypoint", svc.name, cityData.cityName)
                        end,
                    })
                    break
                end
            end
        end
    else
        -- Not in a city: show travel planner, recent destinations, useful actions
        table.insert(items, {
            label = "Travel Planner",
            shortLabel = "Travel",
            color = { r = 0.4, g = 0.85, b = 1.0 },
            action = function()
                local tpFrame = DXD:GetModule("TravelPlannerFrame")
                if tpFrame then tpFrame:Toggle() end
            end,
        })

        table.insert(items, {
            label = "Clear Waypoint",
            shortLabel = "Clear",
            color = { r = 0.9, g = 0.25, b = 0.25 },
            action = function()
                DXD:ClearTarget()
                DXD:Print("Waypoint cleared.")
            end,
        })

        table.insert(items, {
            label = "Settings",
            shortLabel = "Settings",
            color = { r = 0.6, g = 0.6, b = 0.65 },
            action = function()
                local settings = DXD:GetModule("SettingsPanel")
                if settings then settings:Toggle() end
            end,
        })

        -- Add M+ dungeons as quick access
        if DXD.MythicPlusDungeons and DXD.MythicPlusDungeons.dungeons then
            for _, dg in ipairs(DXD.MythicPlusDungeons.dungeons) do
                if #items >= MAX_ITEMS then break end
                if not dg.legacy then
                    table.insert(items, {
                        label = dg.name,
                        shortLabel = dg.name:sub(1, 12),
                        color = { r = 1.0, g = 0.5, b = 0.0 },
                        action = function()
                            DXD:SetTarget(dg.entranceMapID, dg.entranceX, dg.entranceY,
                                "dungeon", dg.name, "Dungeon Entrance")
                        end,
                    })
                end
            end
        end
    end

    return items
end

------------------------------------------------------------------------
-- FRAME CREATION
------------------------------------------------------------------------

local function CreateMenuItem(index)
    local item = CreateFrame("Button", nil, menuFrame, "BackdropTemplate")
    item:SetSize(ITEM_SIZE, ITEM_SIZE)
    item:SetFrameStrata("TOOLTIP")
    item:SetFrameLevel(200)

    item:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })

    item.label = item:CreateFontString(nil, "OVERLAY")
    item.label:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    item.label:SetShadowColor(0, 0, 0, 0.8)
    item.label:SetShadowOffset(1, -1)
    item.label:SetPoint("CENTER")
    item.label:SetWidth(ITEM_SIZE - 4)
    item.label:SetJustifyH("CENTER")
    item.label:SetWordWrap(true)

    item:SetScript("OnEnter", function(self)
        if self.itemColor then
            self:SetBackdropColor(self.itemColor.r, self.itemColor.g, self.itemColor.b, 0.35)
            self:SetBackdropBorderColor(self.itemColor.r, self.itemColor.g, self.itemColor.b, 0.8)
        end
        if centerLabel and self.itemData then
            centerLabel:SetText(self.itemData.label)
        end
    end)

    item:SetScript("OnLeave", function(self)
        if self.itemColor then
            self:SetBackdropColor(self.itemColor.r, self.itemColor.g, self.itemColor.b, 0.12)
            self:SetBackdropBorderColor(self.itemColor.r, self.itemColor.g, self.itemColor.b, 0.3)
        end
        if centerLabel then
            centerLabel:SetText("")
        end
    end)

    item:SetScript("OnClick", function(self)
        if self.itemData and self.itemData.action then
            self.itemData.action()
        end
        RadialMenu:Hide()
    end)

    item:Hide()
    return item
end

local function CreateRadialMenu()
    menuFrame = CreateFrame("Frame", "DXDRadialMenu", UIParent)
    menuFrame:SetSize(RING_RADIUS * 2 + ITEM_SIZE, RING_RADIUS * 2 + ITEM_SIZE)
    menuFrame:SetFrameStrata("TOOLTIP")
    menuFrame:SetFrameLevel(199)
    menuFrame:EnableMouse(true)

    -- Center hub
    local centerBg = CreateFrame("Frame", nil, menuFrame, "BackdropTemplate")
    centerBg:SetSize(CENTER_SIZE, CENTER_SIZE)
    centerBg:SetPoint("CENTER")
    centerBg:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    local bg = Config.COLORS.PANEL_BG
    centerBg:SetBackdropColor(bg.r, bg.g, bg.b, 0.85)
    centerBg:SetBackdropBorderColor(0.4, 0.85, 1.0, 0.2)

    centerLabel = menuFrame:CreateFontString(nil, "OVERLAY")
    centerLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    centerLabel:SetShadowColor(0, 0, 0, 0.8)
    centerLabel:SetShadowOffset(1, -1)
    centerLabel:SetPoint("CENTER", centerBg)
    centerLabel:SetWidth(CENTER_SIZE - 4)
    centerLabel:SetJustifyH("CENTER")
    centerLabel:SetWordWrap(true)
    local primary = Config.COLORS.TEXT_PRIMARY
    centerLabel:SetTextColor(primary.r, primary.g, primary.b, 0.9)

    -- Pre-create item slots
    for i = 1, MAX_ITEMS do
        menuItems[i] = CreateMenuItem(i)
    end

    menuFrame:Hide()
end

------------------------------------------------------------------------
-- SHOW / HIDE
------------------------------------------------------------------------

function RadialMenu:Show()
    if not menuFrame then return end
    if not DXD.db or not DXD.db.radialMenuEnabled then return end

    local items = GetMenuItems()
    if #items == 0 then return end

    -- Position at cursor
    local cursorX, cursorY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    cursorX = cursorX / scale
    cursorY = cursorY / scale

    menuFrame:ClearAllPoints()
    menuFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cursorX, cursorY)

    -- Position items in a ring
    local count = math.min(#items, MAX_ITEMS)
    local angleStep = (2 * math.pi) / count
    local startAngle = -math.pi / 2  -- Start at top

    for i = 1, MAX_ITEMS do
        if i <= count then
            local item = menuItems[i]
            local angle = startAngle + (i - 1) * angleStep
            local x = math.cos(angle) * RING_RADIUS
            local y = math.sin(angle) * RING_RADIUS

            item:ClearAllPoints()
            item:SetPoint("CENTER", menuFrame, "CENTER", x, y)

            local data = items[i]
            item.itemData = data
            item.itemColor = data.color

            item:SetBackdropColor(data.color.r, data.color.g, data.color.b, 0.12)
            item:SetBackdropBorderColor(data.color.r, data.color.g, data.color.b, 0.3)
            item.label:SetText(data.shortLabel)
            item.label:SetTextColor(data.color.r, data.color.g, data.color.b, 0.9)

            item:Show()
        else
            menuItems[i]:Hide()
        end
    end

    centerLabel:SetText("")
    menuFrame:Show()
    isShowing = true
end

function RadialMenu:Hide()
    if menuFrame then
        menuFrame:Hide()
    end
    isShowing = false
end

function RadialMenu:IsShown()
    return isShowing
end

------------------------------------------------------------------------
-- KEYBINDING
------------------------------------------------------------------------

local function SetupKeybinding()
    local keyFrame = CreateFrame("Frame", "DXDRadialKeyFrame", UIParent)
    keyFrame:SetPropagateKeyboardInput(true)

    keyFrame:SetScript("OnKeyDown", function(self, key)
        if not DXD.db or not DXD.db.radialMenuEnabled then return end

        local boundKey = DXD.db.radialMenuKey or "`"
        if key == boundKey then
            self:SetPropagateKeyboardInput(false)
            if not isShowing then
                RadialMenu:Show()
            end
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)

    keyFrame:SetScript("OnKeyUp", function(self, key)
        local boundKey = DXD.db.radialMenuKey or "`"
        if key == boundKey then
            self:SetPropagateKeyboardInput(true)
            if isShowing then
                RadialMenu:Hide()
            end
        end
    end)
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function RadialMenu:Initialize()
    CreateRadialMenu()
    SetupKeybinding()
    DXD:Debug("RadialMenu initialized")
end
