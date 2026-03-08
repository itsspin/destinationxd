------------------------------------------------------------------------
-- DestinationXD - TravelPlannerFrame.lua
-- The zone browser / route planner window
-- Clean, intuitive design with proper scroll, dungeon support, icons
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local TravelPlannerFrame = {}
DXD:RegisterModule("TravelPlannerFrame", TravelPlannerFrame)

local Config = DXD.Config
local Utils = DXD.Utils
local Widgets = DXD.Widgets

-- Main frame
local travelFrame
local zoneListContent
local zoneScrollContainer
local routePanel
local searchBox

-- Zone list state
local expandedContinents = {}
local selectedZone = nil

-- Forward declarations for local functions
local PopulateZoneList, OnZoneSelected, DisplayRoute

-- Zone entry frames pool
local zoneEntryPool = {}
local activeEntries = {}

-- Type icons (safe Unicode that WoW renders reliably)
local TYPE_ICONS = {
    capital  = "|cffffcc00\226\152\134|r ",   -- ☆ star
    dungeon  = "|cffa335ee\226\154\148|r ",    -- ⚔ swords (purple)
    zone     = "",                              -- no icon for regular zones
}

-- Filter state
local currentFilter = ""

------------------------------------------------------------------------
-- FRAME CREATION
------------------------------------------------------------------------

local function CreateTravelPlannerWindow()
    -- Main window
    travelFrame = CreateFrame("Frame", "DestinationXDTravelFrame", UIParent, "BackdropTemplate")
    travelFrame:SetSize(320, 520)
    travelFrame:SetPoint("CENTER", -200, 0)
    travelFrame:SetFrameStrata("HIGH")
    travelFrame:SetFrameLevel(50)

    -- Frosted glass background
    travelFrame:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    local bg = Config.COLORS.PANEL_BG
    travelFrame:SetBackdropColor(bg.r, bg.g, bg.b, 0.88)
    travelFrame:SetBackdropBorderColor(1, 1, 1, 0.06)

    -- Make movable and closeable
    travelFrame:SetMovable(true)
    travelFrame:EnableMouse(true)
    travelFrame:RegisterForDrag("LeftButton")
    travelFrame:SetScript("OnDragStart", travelFrame.StartMoving)
    travelFrame:SetScript("OnDragStop", travelFrame.StopMovingOrSizing)
    travelFrame:SetClampedToScreen(true)
    table.insert(UISpecialFrames, "DestinationXDTravelFrame")

    -- Title
    local title = travelFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.HEADER, "OUTLINE")
    title:SetShadowColor(0, 0, 0, 0.5)
    title:SetShadowOffset(1, -1)
    title:SetPoint("TOPLEFT", 14, -12)
    local secondary = Config.COLORS.TEXT_SECONDARY
    title:SetTextColor(secondary.r, secondary.g, secondary.b, secondary.a)
    title:SetText("DESTINATION")

    -- Close button
    local closeBtn = Widgets.CreateCloseButton(travelFrame)
    closeBtn:SetPoint("TOPRIGHT", -8, -8)

    -- Search/filter box
    searchBox = CreateFrame("EditBox", nil, travelFrame, "BackdropTemplate")
    searchBox:SetSize(288, 22)
    searchBox:SetPoint("TOPLEFT", 14, -36)
    searchBox:SetAutoFocus(false)
    searchBox:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    searchBox:SetShadowColor(0, 0, 0, 0.5)
    searchBox:SetShadowOffset(1, -1)
    searchBox:SetTextColor(0.85, 0.85, 0.90, 0.8)
    searchBox:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    searchBox:SetBackdropColor(0.05, 0.05, 0.08, 0.5)
    searchBox:SetBackdropBorderColor(1, 1, 1, 0.06)
    searchBox:SetTextInsets(8, 8, 0, 0)

    -- Placeholder text
    local placeholder = searchBox:CreateFontString(nil, "ARTWORK")
    placeholder:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    placeholder:SetShadowColor(0, 0, 0, 0.5)
    placeholder:SetShadowOffset(1, -1)
    placeholder:SetPoint("LEFT", 8, 0)
    placeholder:SetTextColor(0.45, 0.45, 0.50, 0.5)
    placeholder:SetText("Search zones & dungeons...")

    searchBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        if text and text ~= "" then
            placeholder:Hide()
            currentFilter = strlower(text)
        else
            placeholder:Show()
            currentFilter = ""
        end
        PopulateZoneList()
    end)

    searchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    searchBox:SetScript("OnEditFocusGained", function(self)
        placeholder:Hide()
    end)

    searchBox:SetScript("OnEditFocusLost", function(self)
        if not self:GetText() or self:GetText() == "" then
            placeholder:Show()
        end
    end)

    -- Zone list scroll area (larger, accounting for search box)
    zoneScrollContainer = Widgets.CreateScrollFrame(travelFrame, 288, 290)
    zoneScrollContainer:SetPoint("TOPLEFT", 14, -64)
    zoneListContent = zoneScrollContainer.content

    -- Route panel (at the bottom)
    routePanel = CreateFrame("Frame", nil, travelFrame, "BackdropTemplate")
    routePanel:SetSize(288, 140)
    routePanel:SetPoint("BOTTOMLEFT", 14, 14)
    routePanel:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    routePanel:SetBackdropColor(0.05, 0.05, 0.08, 0.4)
    routePanel:SetBackdropBorderColor(1, 1, 1, 0.04)
    routePanel:Hide()

    -- Route title
    routePanel.title = routePanel:CreateFontString(nil, "OVERLAY")
    routePanel.title:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.ROUTE_STEP, "OUTLINE")
    routePanel.title:SetShadowColor(0, 0, 0, 0.5)
    routePanel.title:SetShadowOffset(1, -1)
    routePanel.title:SetPoint("TOPLEFT", 8, -8)
    routePanel.title:SetTextColor(secondary.r, secondary.g, secondary.b, secondary.a)
    routePanel.title:SetWidth(270)

    -- Route steps container
    routePanel.stepsText = routePanel:CreateFontString(nil, "OVERLAY")
    routePanel.stepsText:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.ROUTE_STEP, "OUTLINE")
    routePanel.stepsText:SetShadowColor(0, 0, 0, 0.5)
    routePanel.stepsText:SetShadowOffset(1, -1)
    routePanel.stepsText:SetPoint("TOPLEFT", routePanel.title, "BOTTOMLEFT", 0, -6)
    routePanel.stepsText:SetWidth(270)
    routePanel.stepsText:SetJustifyH("LEFT")
    routePanel.stepsText:SetWordWrap(true)
    local primary = Config.COLORS.TEXT_PRIMARY
    routePanel.stepsText:SetTextColor(primary.r, primary.g, primary.b, primary.a)

    -- Total time
    routePanel.timeText = routePanel:CreateFontString(nil, "OVERLAY")
    routePanel.timeText:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.LABEL, "OUTLINE")
    routePanel.timeText:SetShadowColor(0, 0, 0, 0.5)
    routePanel.timeText:SetShadowOffset(1, -1)
    routePanel.timeText:SetPoint("BOTTOMLEFT", 8, 28)
    local tertiary = Config.COLORS.TEXT_TERTIARY
    routePanel.timeText:SetTextColor(tertiary.r, tertiary.g, tertiary.b, tertiary.a)

    -- GO button (styled, not just text)
    routePanel.goBtn = CreateFrame("Button", nil, routePanel, "BackdropTemplate")
    routePanel.goBtn:SetSize(50, 24)
    routePanel.goBtn:SetPoint("BOTTOMRIGHT", -8, 6)
    routePanel.goBtn:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    local goColor = Config.COLORS.BEACON_WAYPOINT
    routePanel.goBtn:SetBackdropColor(goColor.r, goColor.g, goColor.b, 0.15)
    routePanel.goBtn:SetBackdropBorderColor(goColor.r, goColor.g, goColor.b, 0.3)

    local goLabel = routePanel.goBtn:CreateFontString(nil, "OVERLAY")
    goLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    goLabel:SetShadowColor(0, 0, 0, 0.5)
    goLabel:SetShadowOffset(1, -1)
    goLabel:SetPoint("CENTER")
    goLabel:SetText("GO")
    goLabel:SetTextColor(goColor.r, goColor.g, goColor.b, 0.9)

    routePanel.goBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(goColor.r, goColor.g, goColor.b, 0.3)
        self:SetBackdropBorderColor(goColor.r, goColor.g, goColor.b, 0.6)
        goLabel:SetTextColor(1, 1, 1, 1)
    end)

    routePanel.goBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(goColor.r, goColor.g, goColor.b, 0.15)
        self:SetBackdropBorderColor(goColor.r, goColor.g, goColor.b, 0.3)
        goLabel:SetTextColor(goColor.r, goColor.g, goColor.b, 0.9)
    end)

    routePanel.goBtn:SetScript("OnClick", function()
        if routePanel.currentRoute then
            local planner = DXD:GetModule("TravelPlanner")
            if planner then
                planner:StartRoute(routePanel.currentRoute)
                travelFrame:Hide()
            end
        end
    end)

    -- Populate zone list
    PopulateZoneList()

    travelFrame:Hide()
end

------------------------------------------------------------------------
-- ZONE LIST POPULATION
------------------------------------------------------------------------

local function GetOrCreateEntry(index)
    if zoneEntryPool[index] then
        return zoneEntryPool[index]
    end

    local entry = CreateFrame("Button", nil, zoneListContent)
    entry:SetSize(280, 22)

    -- Highlight background (subtle)
    entry.bg = entry:CreateTexture(nil, "BACKGROUND")
    entry.bg:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    entry.bg:SetAllPoints()
    entry.bg:SetVertexColor(1, 1, 1, 0)

    entry.text = entry:CreateFontString(nil, "OVERLAY")
    entry.text:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.ZONE_NAME, "OUTLINE")
    entry.text:SetShadowColor(0, 0, 0, 0.5)
    entry.text:SetShadowOffset(1, -1)
    entry.text:SetPoint("LEFT", 4, 0)
    entry.text:SetWidth(268)
    entry.text:SetJustifyH("LEFT")

    -- Selection indicator (left edge bar)
    entry.selBar = entry:CreateTexture(nil, "ARTWORK")
    entry.selBar:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    entry.selBar:SetSize(2, 16)
    entry.selBar:SetPoint("LEFT", -1, 0)
    entry.selBar:Hide()

    local secondary = Config.COLORS.TEXT_SECONDARY
    local primary = Config.COLORS.TEXT_PRIMARY
    local tertiary = Config.COLORS.TEXT_TERTIARY

    entry:SetScript("OnEnter", function(self)
        if not self.isContinent then
            self.text:SetTextColor(primary.r, primary.g, primary.b, primary.a)
            self.bg:SetVertexColor(1, 1, 1, 0.03)
        end
    end)

    entry:SetScript("OnLeave", function(self)
        self.bg:SetVertexColor(1, 1, 1, 0)
        if self == selectedZone then
            self.text:SetTextColor(primary.r, primary.g, primary.b, primary.a)
        elseif self.isContinent then
            self.text:SetTextColor(tertiary.r, tertiary.g, tertiary.b, tertiary.a)
        else
            self.text:SetTextColor(secondary.r, secondary.g, secondary.b, secondary.a)
        end
    end)

    zoneEntryPool[index] = entry
    return entry
end

--- Get the display prefix for a zone entry
local function GetZonePrefix(zoneData)
    if zoneData.capital then
        return TYPE_ICONS.capital
    elseif zoneData.dungeon then
        return TYPE_ICONS.dungeon
    end
    return TYPE_ICONS.zone
end

PopulateZoneList = function()
    -- Clear existing
    for _, entry in ipairs(activeEntries) do
        entry:Hide()
    end
    wipe(activeEntries)

    if not DXD.ZoneData then
        DXD:Debug("No zone data available for Travel Planner")
        return
    end

    local yOffset = 0
    local entryIndex = 0
    local isFiltering = (currentFilter ~= "")

    -- Sort continents alphabetically
    local continentOrder = {}
    for name in pairs(DXD.ZoneData) do
        table.insert(continentOrder, name)
    end
    table.sort(continentOrder)

    local secondary = Config.COLORS.TEXT_SECONDARY
    local primary = Config.COLORS.TEXT_PRIMARY
    local tertiary = Config.COLORS.TEXT_TERTIARY
    local dungeonColor = { r = 0.60, g = 0.40, b = 0.90, a = 0.70 }

    -- ============================================================
    -- MYTHIC+ DUNGEONS (Quick Access - always shown at top)
    -- ============================================================
    local mplusColor = { r = 1.0, g = 0.50, b = 0.0, a = 0.85 }
    if DXD.MythicPlusDungeons and DXD.MythicPlusDungeons.dungeons then
        local mplusDungeons = DXD.MythicPlusDungeons.dungeons
        local hasMatchingMplus = false

        if isFiltering then
            for _, dg in ipairs(mplusDungeons) do
                if strfind(strlower(dg.name), currentFilter, 1, true)
                    or strfind("mythic", currentFilter, 1, true)
                    or strfind("m+", currentFilter, 1, true)
                    or strfind("dungeon", currentFilter, 1, true) then
                    hasMatchingMplus = true
                    break
                end
            end
        else
            hasMatchingMplus = true
        end

        if hasMatchingMplus then
            entryIndex = entryIndex + 1
            local mplusHeader = GetOrCreateEntry(entryIndex)
            mplusHeader:SetPoint("TOPLEFT", 0, yOffset)
            mplusHeader.isContinent = true
            mplusHeader.continentName = "_mythicplus"
            mplusHeader.selBar:Hide()
            mplusHeader.bg:SetVertexColor(1, 1, 1, 0)

            local mplusExpanded = expandedContinents["_mythicplus"] or isFiltering
            local mplusPrefix = mplusExpanded and "\226\150\190 " or "\226\150\184 "
            mplusHeader.text:SetText(mplusPrefix .. "|cffff8000MYTHIC+ DUNGEONS|r  |cff666670" .. #mplusDungeons .. "|r")
            mplusHeader.text:SetTextColor(mplusColor.r, mplusColor.g, mplusColor.b, 0.70)

            mplusHeader:SetScript("OnClick", function()
                if not isFiltering then
                    expandedContinents["_mythicplus"] = not expandedContinents["_mythicplus"]
                    PopulateZoneList()
                end
            end)

            mplusHeader:Show()
            table.insert(activeEntries, mplusHeader)
            yOffset = yOffset - 24

            if mplusExpanded then
                for _, dg in ipairs(mplusDungeons) do
                    local matchesMplus = not isFiltering
                        or strfind(strlower(dg.name), currentFilter, 1, true)
                        or strfind("mythic", currentFilter, 1, true)
                        or strfind("m+", currentFilter, 1, true)
                        or strfind("dungeon", currentFilter, 1, true)

                    if matchesMplus then
                        entryIndex = entryIndex + 1
                        local dgEntry = GetOrCreateEntry(entryIndex)
                        dgEntry:SetPoint("TOPLEFT", 14, yOffset)
                        dgEntry.isContinent = false
                        dgEntry.zoneName = dg.name
                        dgEntry.zoneData = {
                            mapID = dg.entranceMapID,
                            dungeon = true,
                            mythicPlus = true,
                            entranceX = dg.entranceX,
                            entranceY = dg.entranceY,
                        }
                        dgEntry.selBar:Hide()
                        dgEntry.bg:SetVertexColor(1, 1, 1, 0)

                        dgEntry.text:SetText("|cffff8000" .. dg.keyLevel .. "|r " .. dg.name)
                        dgEntry.text:SetTextColor(mplusColor.r, mplusColor.g, mplusColor.b, 0.75)

                        dgEntry:SetScript("OnClick", function(self)
                            OnZoneSelected(self, dg.name, self.zoneData)
                        end)

                        dgEntry:Show()
                        table.insert(activeEntries, dgEntry)
                        yOffset = yOffset - 22
                    end
                end
            end
        end
    end

    -- ============================================================
    -- CITY SERVICES (If player is in a city with services data)
    -- ============================================================
    local serviceColor = { r = 0.50, g = 0.85, b = 1.0, a = 0.80 }
    local playerMapID = C_Map.GetBestMapForUnit("player")
    local cityData = playerMapID and DXD.CityServices and DXD.CityServices[playerMapID]

    if cityData then
        local hasMatchingServices = false
        if isFiltering then
            for _, svc in ipairs(cityData.services) do
                if strfind(strlower(svc.name), currentFilter, 1, true)
                    or strfind(strlower(svc.type), currentFilter, 1, true) then
                    hasMatchingServices = true
                    break
                end
            end
        else
            hasMatchingServices = true
        end

        if hasMatchingServices then
            entryIndex = entryIndex + 1
            local svcHeader = GetOrCreateEntry(entryIndex)
            svcHeader:SetPoint("TOPLEFT", 0, yOffset)
            svcHeader.isContinent = true
            svcHeader.continentName = "_cityservices"
            svcHeader.selBar:Hide()
            svcHeader.bg:SetVertexColor(1, 1, 1, 0)

            local svcExpanded = expandedContinents["_cityservices"] or isFiltering
            local svcPrefix = svcExpanded and "\226\150\190 " or "\226\150\184 "
            svcHeader.text:SetText(svcPrefix .. "|cff55d4ff" .. string.upper(cityData.cityName) .. " SERVICES|r")
            svcHeader.text:SetTextColor(serviceColor.r, serviceColor.g, serviceColor.b, 0.70)

            svcHeader:SetScript("OnClick", function()
                if not isFiltering then
                    expandedContinents["_cityservices"] = not expandedContinents["_cityservices"]
                    PopulateZoneList()
                end
            end)

            svcHeader:Show()
            table.insert(activeEntries, svcHeader)
            yOffset = yOffset - 24

            if svcExpanded then
                for _, svc in ipairs(cityData.services) do
                    local matchesSvc = not isFiltering
                        or strfind(strlower(svc.name), currentFilter, 1, true)
                        or strfind(strlower(svc.type), currentFilter, 1, true)

                    if matchesSvc then
                        entryIndex = entryIndex + 1
                        local svcEntry = GetOrCreateEntry(entryIndex)
                        svcEntry:SetPoint("TOPLEFT", 14, yOffset)
                        svcEntry.isContinent = false
                        svcEntry.zoneName = svc.name
                        svcEntry.zoneData = {
                            mapID = playerMapID,
                            x = svc.x,
                            y = svc.y,
                            service = true,
                            serviceType = svc.type,
                        }
                        svcEntry.selBar:Hide()
                        svcEntry.bg:SetVertexColor(1, 1, 1, 0)

                        -- Color based on service type
                        local svcInfo = DXD.ServiceIcons and DXD.ServiceIcons[svc.type]
                        local svcCol = svcInfo and svcInfo.color or serviceColor
                        svcEntry.text:SetText(svc.name)
                        svcEntry.text:SetTextColor(svcCol.r, svcCol.g, svcCol.b, 0.80)

                        svcEntry:SetScript("OnClick", function(self)
                            -- Direct beacon to service location
                            DXD:SetTarget(playerMapID, svc.x, svc.y, "waypoint", svc.name, cityData.cityName)
                            if travelFrame then travelFrame:Hide() end
                        end)

                        svcEntry:Show()
                        table.insert(activeEntries, svcEntry)
                        yOffset = yOffset - 22
                    end
                end
            end
        end
    end

    -- ============================================================
    -- SEPARATOR
    -- ============================================================
    if entryIndex > 0 then
        yOffset = yOffset - 6
    end

    -- ============================================================
    -- ZONE LIST (Continents & Zones)
    -- ============================================================
    for _, continentName in ipairs(continentOrder) do
        local continent = DXD.ZoneData[continentName]

        -- When filtering, check if any children match
        local hasMatchingChildren = false
        local matchingZones = {}
        if continent.children then
            local zoneOrder = {}
            for zoneName in pairs(continent.children) do
                table.insert(zoneOrder, zoneName)
            end
            table.sort(zoneOrder)

            for _, zoneName in ipairs(zoneOrder) do
                if not isFiltering or strfind(strlower(zoneName), currentFilter, 1, true) then
                    hasMatchingChildren = true
                    table.insert(matchingZones, zoneName)
                end
            end
        end

        -- Skip continents with no matching children when filtering
        if isFiltering and not hasMatchingChildren then
            -- skip
        else
            entryIndex = entryIndex + 1

            local continentEntry = GetOrCreateEntry(entryIndex)
            continentEntry:SetPoint("TOPLEFT", 0, yOffset)
            continentEntry.isContinent = true
            continentEntry.continentName = continentName
            continentEntry.selBar:Hide()
            continentEntry.bg:SetVertexColor(1, 1, 1, 0)

            -- Count children (total, not filtered)
            local childCount = 0
            if continent.children then
                for _ in pairs(continent.children) do
                    childCount = childCount + 1
                end
            end

            -- Count dungeons separately for display
            local dungeonCount = 0
            local zoneCount = 0
            if continent.children then
                for _, zone in pairs(continent.children) do
                    if zone.dungeon then
                        dungeonCount = dungeonCount + 1
                    else
                        zoneCount = zoneCount + 1
                    end
                end
            end

            local isExpanded = expandedContinents[continentName] or isFiltering
            local prefix = isExpanded and "\226\150\190 " or "\226\150\184 "  -- ▾ or ▸

            -- Show count breakdown
            local countStr
            if dungeonCount > 0 then
                countStr = zoneCount .. " + " .. dungeonCount .. "d"
            else
                countStr = tostring(childCount)
            end
            continentEntry.text:SetText(prefix .. string.upper(continentName) .. "  |cff666670" .. countStr .. "|r")
            continentEntry.text:SetTextColor(tertiary.r, tertiary.g, tertiary.b, 0.55)

            continentEntry:SetScript("OnClick", function(self)
                if not isFiltering then
                    expandedContinents[continentName] = not expandedContinents[continentName]
                    PopulateZoneList()
                end
            end)

            continentEntry:Show()
            table.insert(activeEntries, continentEntry)
            yOffset = yOffset - 24

            -- Show children if expanded or filtering
            if isExpanded and #matchingZones > 0 then
                for _, zoneName in ipairs(matchingZones) do
                    local zone = continent.children[zoneName]
                    entryIndex = entryIndex + 1

                    local zoneEntry = GetOrCreateEntry(entryIndex)
                    zoneEntry:SetPoint("TOPLEFT", 14, yOffset)
                    zoneEntry.isContinent = false
                    zoneEntry.zoneName = zoneName
                    zoneEntry.zoneData = zone
                    zoneEntry.selBar:Hide()
                    zoneEntry.bg:SetVertexColor(1, 1, 1, 0)

                    local prefix = GetZonePrefix(zone)
                    zoneEntry.text:SetText(prefix .. zoneName)

                    -- Color dungeons differently
                    if zone.dungeon then
                        zoneEntry.text:SetTextColor(dungeonColor.r, dungeonColor.g, dungeonColor.b, dungeonColor.a)
                    else
                        zoneEntry.text:SetTextColor(secondary.r, secondary.g, secondary.b, secondary.a)
                    end

                    zoneEntry:SetScript("OnClick", function(self)
                        OnZoneSelected(self, zoneName, zone)
                    end)

                    zoneEntry:Show()
                    table.insert(activeEntries, zoneEntry)
                    yOffset = yOffset - 22
                end
            end
        end
    end

    -- Update content height with extra padding at bottom for scroll
    zoneListContent:SetHeight(math.abs(yOffset) + 40)
end

------------------------------------------------------------------------
-- ZONE SELECTION & ROUTE DISPLAY
------------------------------------------------------------------------

OnZoneSelected = function(entry, zoneName, zoneData)
    local primary = Config.COLORS.TEXT_PRIMARY
    local secondary = Config.COLORS.TEXT_SECONDARY
    local dungeonColor = { r = 0.60, g = 0.40, b = 0.90, a = 0.70 }

    -- Deselect previous
    if selectedZone then
        local prevData = selectedZone.zoneData
        if prevData and prevData.dungeon then
            selectedZone.text:SetTextColor(dungeonColor.r, dungeonColor.g, dungeonColor.b, dungeonColor.a)
        else
            selectedZone.text:SetTextColor(secondary.r, secondary.g, secondary.b, secondary.a)
        end
        selectedZone.selBar:Hide()
    end

    -- Select this zone
    selectedZone = entry
    entry.text:SetTextColor(primary.r, primary.g, primary.b, primary.a)

    -- Show selection bar with beacon color
    local beaconColor = zoneData.dungeon and Config.COLORS.BEACON_DUNGEON or Config.COLORS.BEACON_TRAVEL
    entry.selBar:SetVertexColor(beaconColor.r, beaconColor.g, beaconColor.b, 0.8)
    entry.selBar:Show()

    -- If this is a M+ dungeon with entrance coords, set beacon directly
    if zoneData.mythicPlus and zoneData.entranceX and zoneData.entranceY then
        -- Show route info then navigate to dungeon entrance
        routePanel.title:SetText("|cffff8000M+|r " .. zoneName)
        routePanel.stepsText:SetText("Navigate to dungeon entrance")
        routePanel.timeText:SetText("")
        routePanel.currentRoute = nil

        -- Create a direct GO action
        routePanel.goBtn:Show()
        routePanel.goBtn:SetScript("OnClick", function()
            DXD:SetTarget(zoneData.mapID, zoneData.entranceX, zoneData.entranceY,
                "dungeon", zoneName, "Dungeon Entrance")
            if travelFrame then travelFrame:Hide() end
        end)
        routePanel:Show()
        return
    end

    -- If this is a city service, navigate directly
    if zoneData.service and zoneData.x and zoneData.y then
        DXD:SetTarget(zoneData.mapID, zoneData.x, zoneData.y, "waypoint", zoneName)
        if travelFrame then travelFrame:Hide() end
        return
    end

    -- Compute route for regular zones
    local fromMap = C_Map.GetBestMapForUnit("player")
    local toMap = zoneData.mapID

    if not fromMap then
        DXD:Print("Cannot determine current location.")
        return
    end

    if not toMap then
        DXD:Print("No map ID for " .. zoneName)
        return
    end

    local planner = DXD:GetModule("TravelPlanner")
    if not planner then return end

    local route = planner:FindRoute(fromMap, toMap)
    DisplayRoute(zoneName, route, zoneData)
end

DisplayRoute = function(destName, route, zoneData)
    if not route then
        routePanel:Hide()
        return
    end

    local secondary = Config.COLORS.TEXT_SECONDARY

    -- Route title
    local currentInfo = C_Map.GetMapInfo(C_Map.GetBestMapForUnit("player") or 0)
    local fromName = currentInfo and currentInfo.name or "Here"
    local arrow = " \226\134\146 "  -- →
    routePanel.title:SetText(fromName .. arrow .. destName)

    if route.sameZone then
        routePanel.stepsText:SetText("You're already here!")
        routePanel.timeText:SetText("")
        routePanel.goBtn:Hide()
    elseif #route.steps == 0 then
        routePanel.stepsText:SetText("No route found.")
        routePanel.timeText:SetText("")
        routePanel.goBtn:Hide()
    else
        -- Format steps
        local routeDisplay = DXD:GetModule("RouteDisplay")
        local lines = {}
        for i, step in ipairs(route.steps) do
            table.insert(lines, routeDisplay:FormatStep(step, i))
        end
        routePanel.stepsText:SetText(table.concat(lines, "\n"))
        routePanel.timeText:SetText(routeDisplay:FormatTotalTime(route))
        routePanel.currentRoute = route
        routePanel.goBtn:Show()
    end

    routePanel:Show()
end

------------------------------------------------------------------------
-- PUBLIC API
------------------------------------------------------------------------

function TravelPlannerFrame:Toggle()
    if not travelFrame then return end
    if travelFrame:IsShown() then
        travelFrame:Hide()
    else
        travelFrame:Show()
    end
end

function TravelPlannerFrame:Show()
    if travelFrame then travelFrame:Show() end
end

function TravelPlannerFrame:Hide()
    if travelFrame then travelFrame:Hide() end
end

function TravelPlannerFrame:RefreshZoneList()
    if travelFrame and travelFrame:IsShown() then
        PopulateZoneList()
    end
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function TravelPlannerFrame:Initialize()
    C_Timer.After(0.1, function()
        CreateTravelPlannerWindow()
        DXD:Debug("TravelPlannerFrame created")
    end)
end
