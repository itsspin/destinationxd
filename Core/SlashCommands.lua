------------------------------------------------------------------------
-- DestinationXD - SlashCommands.lua
-- /dxd and /way command handling
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

-- Forward declarations for local functions
local ParseWayCommand, SetWaypoint, FindMapIDByName
local PrintHelp, PrintStatus, HandleTestCommand

------------------------------------------------------------------------
-- /dxd COMMANDS
------------------------------------------------------------------------

SLASH_DESTINATIONXD1 = "/dxd"
SLASH_DESTINATIONXD2 = "/destinationxd"

SlashCmdList["DESTINATIONXD"] = function(msg)
    msg = strtrim(msg or "")
    local cmd, args = strsplit(" ", msg, 2)
    cmd = strlower(cmd or "")

    if cmd == "" then
        local settings = DXD:GetModule("SettingsPanel")
        if settings then
            settings:Toggle()
        else
            DXD:Print("Settings panel not available.")
        end

    elseif cmd == "travel" or cmd == "tp" then
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
            DXD:Print("Travel Planner not available.")
        end

    elseif cmd == "clear" then
        DXD:ClearTarget()
        DXD:Print("Waypoint cleared.")

    elseif cmd == "reset" then
        DestinationXDDB = nil
        ReloadUI()

    elseif cmd == "debug" then
        DXD.state.debugMode = not DXD.state.debugMode
        DXD:Print("Debug mode: " .. (DXD.state.debugMode and "|cff44ff44ON|r" or "|cffff4444OFF|r"))

    elseif cmd == "test" then
        local subCmd = strlower(args or "beacon")
        HandleTestCommand(subCmd)

    elseif cmd == "status" then
        PrintStatus()

    else
        PrintHelp()
    end
end

------------------------------------------------------------------------
-- /way COMMANDS (TomTom-compatible)
------------------------------------------------------------------------

if not SlashCmdList["TOMTOM_WAY"] then
    SLASH_DESTINATIONXD_WAY1 = "/way"
    SLASH_DESTINATIONXD_WAY2 = "/waypoint"

    SlashCmdList["DESTINATIONXD_WAY"] = function(msg)
        ParseWayCommand(msg)
    end
end

ParseWayCommand = function(msg)
    msg = strtrim(msg or "")

    if msg == "" then
        DXD:Print("Usage: /way [zone] x y [description]")
        DXD:Print("       /way x y [description]")
        DXD:Print("       /way clear")
        return
    end

    if strlower(msg) == "clear" then
        DXD:ClearTarget()
        DXD:Print("Waypoint cleared.")
        return
    end

    -- Try simple format first: /way x y [desc]
    local x, y, desc = msg:match("^([%d%.]+)[%s,]+([%d%.]+)%s*(.*)")
    if x and y then
        x = tonumber(x)
        y = tonumber(y)
        if x and y then
            SetWaypoint(nil, x / 100, y / 100, desc)
            return
        end
    end

    -- Try zone format: /way Zone Name x y [desc]
    local zone, coordStr = msg:match("^(.-)%s+([%d%.]+[%s,]+[%d%.]+.*)$")
    if zone and coordStr then
        x, y, desc = coordStr:match("^([%d%.]+)[%s,]+([%d%.]+)%s*(.*)")
        if x and y then
            x = tonumber(x)
            y = tonumber(y)
            if x and y then
                SetWaypoint(zone, x / 100, y / 100, desc)
                return
            end
        end
    end

    DXD:Print("Invalid waypoint format. Use: /way [zone] x y [description]")
end

SetWaypoint = function(zoneName, mapX, mapY, description)
    local mapID

    if zoneName and zoneName ~= "" then
        mapID = FindMapIDByName(zoneName)
        if not mapID then
            DXD:Print("Unknown zone: " .. zoneName)
            return
        end
    else
        mapID = C_Map.GetBestMapForUnit("player")
        if not mapID then
            DXD:Print("Cannot determine current zone.")
            return
        end
    end

    if mapX < 0 or mapX > 1 or mapY < 0 or mapY > 1 then
        DXD:Print("Coordinates must be between 0 and 100.")
        return
    end

    local mapInfo = C_Map.GetMapInfo(mapID)
    local zonePrint = mapInfo and mapInfo.name or ("Map " .. mapID)
    local displayX = math.floor(mapX * 1000 + 0.5) / 10
    local displayY = math.floor(mapY * 1000 + 0.5) / 10

    local name = description and description ~= "" and description or nil
    local fullName = zonePrint .. " (" .. displayX .. ", " .. displayY .. ")"
    if name then
        fullName = name .. " - " .. fullName
    end

    DXD:SetTarget(mapID, mapX, mapY, "waypoint", fullName, name)

    -- Also set the WoW supertrack user waypoint
    if UiMapPoint and UiMapPoint.CreateFromCoordinates then
        local uiMapPoint = UiMapPoint.CreateFromCoordinates(mapID, mapX, mapY)
        if uiMapPoint then
            C_Map.SetUserWaypoint(uiMapPoint)
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
    end

    DXD:Print("Waypoint set: |cff00bfff" .. fullName .. "|r")
end

FindMapIDByName = function(name)
    name = strlower(strtrim(name))

    -- Use zone lookup if available
    if DXD.ZoneLookup and DXD.ZoneLookup.FindMapID then
        local id = DXD.ZoneLookup:FindMapID(name)
        if id then return id end
    end

    -- Fallback: iterate through known maps
    for mapID = 1, 2500 do
        local info = C_Map.GetMapInfo(mapID)
        if info and info.name and strlower(info.name) == name then
            return mapID
        end
    end

    return nil
end

------------------------------------------------------------------------
-- HELP & STATUS
------------------------------------------------------------------------

PrintHelp = function()
    DXD:Print("DestinationXD Commands:")
    DXD:Print("  |cff66d9ef/dxd|r - Open settings")
    DXD:Print("  |cff66d9ef/dxd travel|r - Open Travel Planner")
    DXD:Print("  |cff66d9ef/dxd clear|r - Clear current waypoint")
    DXD:Print("  |cff66d9ef/dxd reset|r - Reset all settings")
    DXD:Print("  |cff66d9ef/dxd debug|r - Toggle debug mode")
    DXD:Print("  |cff66d9ef/dxd test [type]|r - Run test (beacon/elevation/travel)")
    DXD:Print("  |cff66d9ef/way x y [desc]|r - Set waypoint")
    DXD:Print("  |cff66d9ef/way Zone x y|r - Set waypoint in specific zone")
end

PrintStatus = function()
    local s = DXD.state
    DXD:Print("--- DestinationXD Status ---")
    DXD:Print("Position: " .. string.format("%.1f, %.1f, %.1f", s.playerX, s.playerY, s.playerZ))
    DXD:Print("Map ID: " .. tostring(s.playerMapID))
    DXD:Print("Has Target: " .. tostring(s.hasTarget))
    if s.hasTarget then
        DXD:Print("Target Type: " .. s.targetType)
        DXD:Print("Target: " .. (s.targetName or "unnamed"))
        DXD:Print("Distance: " .. DXD.Utils.FormatDistance(s.distance3D)
            .. " (H:" .. DXD.Utils.FormatDistance(s.distanceHorizontal)
            .. " V:" .. DXD.Utils.FormatDistance(s.distanceVertical) .. ")")
        DXD:Print("Elevation: " .. s.elevationState .. " (" .. string.format("%.1f", s.elevationDelta) .. "y)")
    end
    DXD:Print("Speed: " .. string.format("%.1f", DXD.Utils.GetSpeed()) .. " y/s")
end

------------------------------------------------------------------------
-- TEST COMMANDS
------------------------------------------------------------------------

HandleTestCommand = function(subCmd)
    if subCmd == "beacon" then
        local mapID = C_Map.GetBestMapForUnit("player")
        local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
        if pos then
            local x, y = pos:GetXY()
            local facing = GetPlayerFacing() or 0
            local offsetX = math.sin(facing) * 0.02
            local offsetY = -math.cos(facing) * 0.02
            local testX = x + offsetX
            local testY = y + offsetY
            DXD:SetTarget(mapID, testX, testY, "waypoint", "Test Beacon", "Test waypoint ahead")
            if UiMapPoint and UiMapPoint.CreateFromCoordinates then
                local uiMapPoint = UiMapPoint.CreateFromCoordinates(mapID, testX, testY)
                if uiMapPoint then
                    C_Map.SetUserWaypoint(uiMapPoint)
                    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
                end
            end
            DXD:Print("Test beacon spawned ahead.")
        else
            DXD:Print("Cannot determine position for test.")
        end

    elseif subCmd == "elevation" then
        local mapID = C_Map.GetBestMapForUnit("player")
        local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
        if pos then
            local x, y = pos:GetXY()
            DXD:SetTarget(mapID, x + 0.01, y + 0.01, "waypoint", "Elevation Test", "Test nearby waypoint")
            if UiMapPoint and UiMapPoint.CreateFromCoordinates then
                local uiMapPoint = UiMapPoint.CreateFromCoordinates(mapID, x + 0.01, y + 0.01)
                if uiMapPoint then
                    C_Map.SetUserWaypoint(uiMapPoint)
                    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
                end
            end
            DXD:Print("Test waypoint set nearby.")
        end

    elseif subCmd == "travel" then
        DXD:Print("Travel planner test: computing route from current location...")
        local planner = DXD:GetModule("TravelPlanner")
        if planner and planner.TestRoute then
            planner:TestRoute()
        end

    elseif subCmd == "performance" then
        DXD:Print("Starting 60-second performance benchmark...")
        local startMem = collectgarbage("count")
        local startTime = GetTime()
        C_Timer.After(60, function()
            local endMem = collectgarbage("count")
            local endTime = GetTime()
            DXD:Print("Performance results:")
            DXD:Print("  Duration: " .. string.format("%.1f", endTime - startTime) .. "s")
            DXD:Print("  Memory delta: " .. string.format("%.1f", endMem - startMem) .. " KB")
            -- Use modern API if available, fallback to legacy
            if C_AddOns and C_AddOns.GetAddOnMemoryUsage then
                C_AddOns.UpdateAddOnMemoryUsage()
                DXD:Print("  Total addon memory: " .. string.format("%.1f", C_AddOns.GetAddOnMemoryUsage(ADDON_NAME)) .. " KB")
            elseif UpdateAddOnMemoryUsage then
                UpdateAddOnMemoryUsage()
                DXD:Print("  Total addon memory: " .. string.format("%.1f", GetAddOnMemoryUsage(ADDON_NAME)) .. " KB")
            end
        end)

    else
        DXD:Print("Test commands: beacon, elevation, travel, performance")
    end
end
