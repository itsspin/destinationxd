------------------------------------------------------------------------
-- DestinationXD - TravelPlannerFrame.lua
-- The zone browser / route planner window
-- Design: frosted glass, barely there, radical minimalism
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
local routePanel

-- Zone list state
local expandedContinents = {}
local selectedZone = nil

-- Forward declarations for local functions
local PopulateZoneList, OnZoneSelected, DisplayRoute

-- Zone entry frames pool
local zoneEntryPool = {}
local activeEntries = {}

------------------------------------------------------------------------
-- FRAME CREATION
------------------------------------------------------------------------

local function CreateTravelPlannerWindow()
    -- Main window
    travelFrame = CreateFrame("Frame", "DestinationXDTravelFrame", UIParent, "BackdropTemplate")
    travelFrame:SetSize(300, 500)
    travelFrame:SetPoint("CENTER", -200, 0)
    travelFrame:SetFrameStrata("HIGH")
    travelFrame:SetFrameLevel(50)

    -- Frosted glass background - dark, slightly blue, no borders
    travelFrame:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    local bg = Config.COLORS.PANEL_BG
    travelFrame:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
    travelFrame:SetBackdropBorderColor(1, 1, 1, 0.08)  -- 1px inset line at 8% white

    -- Make movable and closeable
    travelFrame:SetMovable(true)
    travelFrame:EnableMouse(true)
    travelFrame:RegisterForDrag("LeftButton")
    travelFrame:SetScript("OnDragStart", travelFrame.StartMoving)
    travelFrame:SetScript("OnDragStop", travelFrame.StopMovingOrSizing)
    travelFrame:SetClampedToScreen(true)
    table.insert(UISpecialFrames, "DestinationXDTravelFrame")

    -- Title: "DESTINATION" in letter-spaced style
    local title = travelFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.HEADER, "OUTLINE")
    title:SetShadowColor(0, 0, 0, 0.5)
    title:SetShadowOffset(1, -1)
    title:SetPoint("TOPLEFT", 12, -12)
    local secondary = Config.COLORS.TEXT_SECONDARY
    title:SetTextColor(secondary.r, secondary.g, secondary.b, secondary.a)
    title:SetText("DESTINATION")

    -- Close button: just ×
    local closeBtn = Widgets.CreateCloseButton(travelFrame)
    closeBtn:SetPoint("TOPRIGHT", -8, -8)

    -- Zone list scroll area
    local zoneScroll = Widgets.CreateScrollFrame(travelFrame, 270, 300)
    zoneScroll:SetPoint("TOPLEFT", 12, -40)
    zoneListContent = zoneScroll.content

    -- Route panel (at the bottom)
    routePanel = CreateFrame("Frame", nil, travelFrame)
    routePanel:SetSize(270, 130)
    routePanel:SetPoint("BOTTOMLEFT", 12, 12)
    routePanel:Hide()

    -- Route title
    routePanel.title = routePanel:CreateFontString(nil, "OVERLAY")
    routePanel.title:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.ROUTE_STEP, "OUTLINE")
    routePanel.title:SetShadowColor(0, 0, 0, 0.5)
    routePanel.title:SetShadowOffset(1, -1)
    routePanel.title:SetPoint("TOPLEFT", 0, 0)
    routePanel.title:SetTextColor(secondary.r, secondary.g, secondary.b, secondary.a)
    routePanel.title:SetWidth(270)

    -- Route steps container
    routePanel.stepsText = routePanel:CreateFontString(nil, "OVERLAY")
    routePanel.stepsText:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.ROUTE_STEP, "OUTLINE")
    routePanel.stepsText:SetShadowColor(0, 0, 0, 0.5)
    routePanel.stepsText:SetShadowOffset(1, -1)
    routePanel.stepsText:SetPoint("TOPLEFT", routePanel.title, "BOTTOMLEFT", 0, -8)
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
    routePanel.timeText:SetPoint("BOTTOMLEFT", 0, 24)
    local tertiary = Config.COLORS.TEXT_TERTIARY
    routePanel.timeText:SetTextColor(tertiary.r, tertiary.g, tertiary.b, tertiary.a)

    -- GO button
    routePanel.goBtn = Widgets.CreateTextButton(routePanel, "GO", Config.FONT_SIZES.HEADER, function()
        if routePanel.currentRoute then
            local planner = DXD:GetModule("TravelPlanner")
            if planner then
                planner:StartRoute(routePanel.currentRoute)
                travelFrame:Hide()
            end
        end
    end)
    routePanel.goBtn:SetPoint("BOTTOMRIGHT", 0, 20)

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
    entry:SetSize(270, 20)

    entry.text = entry:CreateFontString(nil, "OVERLAY")
    entry.text:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.ZONE_NAME, "OUTLINE")
    entry.text:SetShadowColor(0, 0, 0, 0.5)
    entry.text:SetShadowOffset(1, -1)
    entry.text:SetPoint("LEFT", 0, 0)
    entry.text:SetWidth(260)
    entry.text:SetJustifyH("LEFT")

    -- Selection dot (tiny 2px dot to the left)
    entry.dot = entry:CreateTexture(nil, "ARTWORK")
    entry.dot:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    entry.dot:SetSize(3, 3)
    entry.dot:SetPoint("RIGHT", entry.text, "LEFT", -4, 0)
    entry.dot:Hide()

    local secondary = Config.COLORS.TEXT_SECONDARY
    local primary = Config.COLORS.TEXT_PRIMARY
    local tertiary = Config.COLORS.TEXT_TERTIARY

    entry:SetScript("OnEnter", function(self)
        if not self.isContinent then
            self.text:SetTextColor(primary.r, primary.g, primary.b, primary.a)
        end
    end)

    entry:SetScript("OnLeave", function(self)
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

    -- Sort continents alphabetically
    local continentOrder = {}
    for name in pairs(DXD.ZoneData) do
        table.insert(continentOrder, name)
    end
    table.sort(continentOrder)

    local secondary = Config.COLORS.TEXT_SECONDARY
    local primary = Config.COLORS.TEXT_PRIMARY
    local tertiary = Config.COLORS.TEXT_TERTIARY

    for _, continentName in ipairs(continentOrder) do
        local continent = DXD.ZoneData[continentName]
        entryIndex = entryIndex + 1

        local continentEntry = GetOrCreateEntry(entryIndex)
        continentEntry:SetPoint("TOPLEFT", 0, yOffset)
        continentEntry.isContinent = true
        continentEntry.continentName = continentName

        -- Count children
        local childCount = 0
        if continent.children then
            for _ in pairs(continent.children) do
                childCount = childCount + 1
            end
        end

        local prefix = expandedContinents[continentName] and "\226\150\190 " or "\226\150\184 "  -- ▾ or ▸
        continentEntry.text:SetText(prefix .. string.upper(continentName) .. " (" .. childCount .. ")")
        continentEntry.text:SetTextColor(tertiary.r, tertiary.g, tertiary.b, tertiary.a)
        continentEntry.dot:Hide()

        continentEntry:SetScript("OnClick", function(self)
            expandedContinents[continentName] = not expandedContinents[continentName]
            PopulateZoneList()
        end)

        continentEntry:Show()
        table.insert(activeEntries, continentEntry)
        yOffset = yOffset - 22

        -- Show children if expanded
        if expandedContinents[continentName] and continent.children then
            -- Sort zones
            local zoneOrder = {}
            for zoneName in pairs(continent.children) do
                table.insert(zoneOrder, zoneName)
            end
            table.sort(zoneOrder)

            for _, zoneName in ipairs(zoneOrder) do
                local zone = continent.children[zoneName]
                entryIndex = entryIndex + 1

                local zoneEntry = GetOrCreateEntry(entryIndex)
                zoneEntry:SetPoint("TOPLEFT", 16, yOffset)  -- Indented
                zoneEntry.isContinent = false
                zoneEntry.zoneName = zoneName
                zoneEntry.zoneData = zone

                zoneEntry.text:SetText(zoneName)
                zoneEntry.text:SetTextColor(secondary.r, secondary.g, secondary.b, secondary.a)
                zoneEntry.dot:Hide()

                zoneEntry:SetScript("OnClick", function(self)
                    OnZoneSelected(self, zoneName, zone)
                end)

                zoneEntry:Show()
                table.insert(activeEntries, zoneEntry)
                yOffset = yOffset - 20
            end
        end
    end

    -- Update content height
    zoneListContent:SetHeight(math.abs(yOffset) + 10)
end

------------------------------------------------------------------------
-- ZONE SELECTION & ROUTE DISPLAY
------------------------------------------------------------------------

OnZoneSelected = function(entry, zoneName, zoneData)
    local primary = Config.COLORS.TEXT_PRIMARY
    local secondary = Config.COLORS.TEXT_SECONDARY

    -- Deselect previous
    if selectedZone then
        selectedZone.text:SetTextColor(secondary.r, secondary.g, secondary.b, secondary.a)
        selectedZone.dot:Hide()
    end

    -- Select this zone
    selectedZone = entry
    entry.text:SetTextColor(primary.r, primary.g, primary.b, primary.a)

    -- Show selection dot with beacon color
    local beaconColor = Config.COLORS.BEACON_TRAVEL
    entry.dot:SetVertexColor(beaconColor.r, beaconColor.g, beaconColor.b, 0.8)
    entry.dot:Show()

    -- Compute route
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
    DisplayRoute(zoneName, route)
end

DisplayRoute = function(destName, route)
    if not route then
        routePanel:Hide()
        return
    end

    local secondary = Config.COLORS.TEXT_SECONDARY

    -- Route title
    local currentInfo = C_Map.GetMapInfo(C_Map.GetBestMapForUnit("player") or 0)
    local fromName = currentInfo and currentInfo.name or "Here"
    routePanel.title:SetText(fromName .. " \226\134\146 " .. destName)  -- →

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
    -- Delay creation slightly to ensure all data is loaded
    C_Timer.After(0.1, function()
        CreateTravelPlannerWindow()
        DXD:Debug("TravelPlannerFrame created")
    end)
end
