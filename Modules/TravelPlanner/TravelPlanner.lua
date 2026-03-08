------------------------------------------------------------------------
-- DestinationXD - TravelPlanner.lua
-- Smart route calculation engine using Dijkstra's algorithm
-- Considers portals, hearthstones, same-continent flying, zone adjacency
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local TravelPlanner = {}
DXD:RegisterModule("TravelPlanner", TravelPlanner)

local Utils = DXD.Utils
local Config = DXD.Config

-- Travel method types
local METHOD = {
    WALK_FLY      = 1,
    FLIGHT_PATH   = 2,
    PORTAL        = 3,
    HEARTHSTONE   = 4,
    BOAT_ZEPPELIN = 5,
}

local METHOD_NAMES = {
    [METHOD.WALK_FLY]      = "Fly",
    [METHOD.FLIGHT_PATH]   = "Flight Path",
    [METHOD.PORTAL]        = "Portal",
    [METHOD.HEARTHSTONE]   = "Hearthstone",
    [METHOD.BOAT_ZEPPELIN] = "Transport",
}

local METHOD_ICONS = {
    [METHOD.WALK_FLY]      = "|cff88ddff>>|r",
    [METHOD.FLIGHT_PATH]   = "|cff88ddff>>|r",
    [METHOD.PORTAL]        = "|cffa855f7**|r",
    [METHOD.HEARTHSTONE]   = "|cffff6666<3|r",
    [METHOD.BOAT_ZEPPELIN] = "|cff55ccaa~~|r",
}

-- Route state
local currentRoute = nil
local currentStep = 0

------------------------------------------------------------------------
-- CONTINENT MAPPING
-- Maps zones to their parent continent so we know which zones
-- can be reached by flying within the same continent
------------------------------------------------------------------------

-- Build a reverse lookup: mapID -> continentMapID
local continentForZone = {}
local continentZones = {} -- continentMapID -> { mapID, mapID, ... }

local function BuildContinentLookup()
    if not DXD.ZoneData then return end
    for continentName, continent in pairs(DXD.ZoneData) do
        if continent.children and continent.mapID then
            local contID = continent.mapID
            if not continentZones[contID] then
                continentZones[contID] = {}
            end
            for zoneName, zone in pairs(continent.children) do
                if zone.mapID then
                    continentForZone[zone.mapID] = contID
                    table.insert(continentZones[contID], zone.mapID)
                end
            end
        end
    end
end

--- Check if two maps are on the same continent
local function SameContinent(mapA, mapB)
    if not mapA or not mapB then return false end
    local contA = continentForZone[mapA]
    local contB = continentForZone[mapB]
    if contA and contB and contA == contB then return true end
    -- Also check via WoW API
    if C_Map and C_Map.GetMapInfo then
        local infoA = C_Map.GetMapInfo(mapA)
        local infoB = C_Map.GetMapInfo(mapB)
        if infoA and infoB and infoA.parentMapID and infoB.parentMapID then
            return infoA.parentMapID == infoB.parentMapID
        end
    end
    return false
end

------------------------------------------------------------------------
-- GRAPH BUILDING
------------------------------------------------------------------------

--- Build a travel graph for pathfinding
local function BuildGraph(fromMapID, toMapID)
    local graph = {}  -- [mapID] = { edges = { {to, cost, method, details} } }

    local function AddEdge(src, dst, cost, method, name, details)
        if not graph[src] then
            graph[src] = { edges = {} }
        end
        table.insert(graph[src].edges, {
            to = dst,
            cost = cost,
            method = method,
            name = name,
            details = details,
        })
    end

    local _, playerFaction = UnitFactionGroup("player")

    -- 1. Add portal edges
    if DXD.PortalData then
        for _, portal in ipairs(DXD.PortalData) do
            local src = portal.srcMapID
            local dst = portal.dstMapID
            if src and dst then
                local faction = portal.faction
                if not faction or faction == "Both" or faction == playerFaction then
                    AddEdge(src, dst,
                        portal.travelTime or Config.TRAVEL.PORTAL_CAST_TIME,
                        METHOD.PORTAL, portal.name or "Portal", portal)
                end
            end
        end
    end

    -- 2. Add same-continent fly edges between ALL zones on the same continent
    -- This is what makes routing actually work - you can fly between any two
    -- zones on the same continent
    if DXD.ZoneData then
        for continentName, continent in pairs(DXD.ZoneData) do
            if continent.children then
                local zones = {}
                for zoneName, zone in pairs(continent.children) do
                    if zone.mapID then
                        local faction = zone.faction
                        if not faction or faction == "Both" or faction == playerFaction then
                            table.insert(zones, zone.mapID)
                        end
                    end
                end

                -- Add fly edges between all zone pairs on this continent
                for i = 1, #zones do
                    for j = 1, #zones do
                        if i ~= j then
                            local flyTime = TravelPlanner:EstimateFlyTime(zones[i], zones[j])
                            -- Only add if estimated time is reasonable (same continent)
                            if flyTime and flyTime < 600 then
                                local destInfo = C_Map.GetMapInfo(zones[j])
                                local destName = (destInfo and destInfo.name) or "destination"
                                AddEdge(zones[i], zones[j], flyTime,
                                    METHOD.WALK_FLY,
                                    "Fly to " .. destName)
                            end
                        end
                    end
                end
            end
        end
    end

    -- 3. Add hearthstone edge if relevant
    local hsReady = false
    local hsCooldown = 1
    if C_Container and C_Container.GetItemCooldown then
        local ok, cd = pcall(C_Container.GetItemCooldown, 6948)
        if ok then hsCooldown = cd or 1 end
    elseif GetItemCooldown then
        local ok, cd = pcall(GetItemCooldown, 6948)
        if ok then hsCooldown = cd or 1 end
    end
    hsReady = (hsCooldown == 0)

    if hsReady then
        local hsLocation = GetBindLocation and GetBindLocation()
        if hsLocation then
            local hsMapID = TravelPlanner:FindMapIDForLocation(hsLocation)
            if hsMapID and fromMapID then
                AddEdge(fromMapID, hsMapID,
                    Config.TRAVEL.HS_CAST_TIME,
                    METHOD.HEARTHSTONE,
                    "Hearthstone to " .. hsLocation)
            end
        end
    end

    -- 4. Add Dalaran Hearthstone (if player has it and it's off cooldown)
    -- Item ID 140192 = Dalaran Hearthstone (Broken Isles)
    if C_Container and C_Container.GetItemCooldown then
        local ok, dalHS = pcall(C_Container.GetItemCooldown, 140192)
        if ok and dalHS == 0 then
            AddEdge(fromMapID, 627,  -- Dalaran Broken Isles
                Config.TRAVEL.HS_CAST_TIME,
                METHOD.HEARTHSTONE,
                "Dalaran Hearthstone")
        end
    end

    return graph
end

------------------------------------------------------------------------
-- DIJKSTRA'S PATHFINDING
------------------------------------------------------------------------

function TravelPlanner:FindRoute(fromMapID, toMapID)
    if not fromMapID or not toMapID then return nil end
    if fromMapID == toMapID then
        return { steps = {}, totalCost = 0, sameZone = true }
    end

    -- Check if same continent - direct flight is always an option
    local isSameContinent = SameContinent(fromMapID, toMapID)

    local graph = BuildGraph(fromMapID, toMapID)

    -- Dijkstra's algorithm
    local dist = {}
    local prev = {}
    local visited = {}
    local queue = {}

    dist[fromMapID] = 0
    table.insert(queue, { mapID = fromMapID, cost = 0 })

    while #queue > 0 do
        local minIdx = 1
        for i = 2, #queue do
            if queue[i].cost < queue[minIdx].cost then
                minIdx = i
            end
        end
        local current = table.remove(queue, minIdx)
        local u = current.mapID

        if not visited[u] then
            visited[u] = true
            if u == toMapID then break end

            local node = graph[u]
            if node then
                for _, edge in ipairs(node.edges) do
                    local v = edge.to
                    if not visited[v] then
                        local newDist = (dist[u] or math.huge) + edge.cost
                        if not dist[v] or newDist < dist[v] then
                            dist[v] = newDist
                            prev[v] = { from = u, edge = edge }
                            table.insert(queue, { mapID = v, cost = newDist })
                        end
                    end
                end
            end
        end
    end

    -- Reconstruct path
    if prev[toMapID] then
        local route = { steps = {}, totalCost = dist[toMapID] or 0 }
        local current = toMapID
        while prev[current] do
            local step = prev[current]
            local mapInfo = C_Map.GetMapInfo(step.edge.to)
            table.insert(route.steps, 1, {
                fromMapID = step.from,
                toMapID = step.edge.to,
                method = step.edge.method,
                name = step.edge.name or (METHOD_NAMES[step.edge.method] or "Travel"),
                cost = step.edge.cost,
                details = step.edge.details,
                zoneName = mapInfo and mapInfo.name or "Unknown",
            })
            current = step.from
        end
        return route
    end

    -- No graph path found
    if isSameContinent then
        -- Same continent: just fly there directly
        local flyTime = self:EstimateFlyTime(fromMapID, toMapID)
        local destInfo = C_Map.GetMapInfo(toMapID)
        local destName = destInfo and destInfo.name or "destination"
        return {
            steps = {
                {
                    fromMapID = fromMapID,
                    toMapID = toMapID,
                    method = METHOD.WALK_FLY,
                    name = "Fly to " .. destName,
                    cost = flyTime,
                }
            },
            totalCost = flyTime,
            directFlight = true,
        }
    end

    -- Different continent, no portal path: need to go through a capital
    -- Suggest: go to nearest capital portal room, then portal to destination continent
    local destInfo = C_Map.GetMapInfo(toMapID)
    local destName = destInfo and destInfo.name or "destination"
    return {
        steps = {
            {
                fromMapID = fromMapID,
                toMapID = toMapID,
                method = METHOD.WALK_FLY,
                name = "Travel to " .. destName .. " (use portal room)",
                cost = 120,
            }
        },
        totalCost = 120,
        directFlight = true,
    }
end

------------------------------------------------------------------------
-- ROUTE EXECUTION
------------------------------------------------------------------------

function TravelPlanner:StartRoute(route)
    if not route or not route.steps or #route.steps == 0 then
        DXD:Print("No route to navigate.")
        return
    end

    currentRoute = route
    currentStep = 1
    DXD.state.travelRoute = route
    DXD.state.travelRouteStep = 1

    self:NavigateToStep(1)
    DXD:Print("Route started: " .. #route.steps .. " step(s), " .. Utils.FormatETA(route.totalCost))
end

--- Navigate to a specific step in the route
function TravelPlanner:NavigateToStep(stepIndex)
    if not currentRoute or not currentRoute.steps[stepIndex] then return end

    local step = currentRoute.steps[stepIndex]
    currentStep = stepIndex
    DXD.state.travelRouteStep = stepIndex

    local stepDesc = "Step " .. stepIndex .. "/" .. #currentRoute.steps

    if step.method == METHOD.PORTAL and step.details then
        -- Portal: navigate to the portal's source location
        local portal = step.details
        if portal.srcMapID and portal.srcX and portal.srcY then
            DXD:SetTarget(portal.srcMapID, portal.srcX, portal.srcY,
                "travel", step.name, stepDesc)
        else
            -- Portal without coords - navigate to source zone center
            DXD:SetTarget(step.fromMapID, 0.5, 0.5, "travel", step.name, stepDesc)
        end
    elseif step.method == METHOD.WALK_FLY then
        -- Flying: navigate to destination zone
        -- Use route's final destination coordinates if this is the last step
        if currentRoute.destX and currentRoute.destY then
            DXD:SetTarget(step.toMapID, currentRoute.destX, currentRoute.destY,
                "travel", step.name, stepDesc)
        else
            -- Use zone center as waypoint - beacon will use C_Navigation for real tracking
            DXD:SetTarget(step.toMapID, 0.5, 0.5, "travel", step.name, stepDesc)
        end
    elseif step.method == METHOD.HEARTHSTONE then
        -- Hearthstone: just show the message, no beacon needed
        DXD:Print(stepDesc .. ": Use your " .. step.name)
        -- Auto-advance after cast time
        C_Timer.After(Config.TRAVEL.HS_CAST_TIME + 2, function()
            if currentRoute and currentStep == stepIndex then
                self:AdvanceStep()
            end
        end)
        return
    else
        -- Generic: navigate to source zone
        if step.fromMapID then
            DXD:SetTarget(step.fromMapID, 0.5, 0.5, "travel", step.name, stepDesc)
        end
    end

    DXD:Print(stepDesc .. ": " .. (METHOD_ICONS[step.method] or "") .. " " .. step.name)
end

function TravelPlanner:AdvanceStep()
    if not currentRoute then return end

    local nextStep = currentStep + 1
    if nextStep > #currentRoute.steps then
        self:CompleteRoute()
    else
        self:NavigateToStep(nextStep)
    end
end

function TravelPlanner:CompleteRoute()
    DXD:Print("Route complete! You've arrived.")
    currentRoute = nil
    currentStep = 0
    DXD.state.travelRoute = nil
    DXD.state.travelRouteStep = 0
end

function TravelPlanner:CancelRoute()
    if currentRoute then
        DXD:Print("Route cancelled.")
        currentRoute = nil
        currentStep = 0
        DXD.state.travelRoute = nil
        DXD.state.travelRouteStep = 0
        DXD:ClearTarget()
    end
end

------------------------------------------------------------------------
-- UTILITIES
------------------------------------------------------------------------

function TravelPlanner:EstimateFlyTime(fromMapID, toMapID)
    local HBD = DXD.HBD
    if not HBD then return 120 end

    local fwX, fwY = HBD:GetWorldCoordinatesFromZone(0.5, 0.5, fromMapID)
    local twX, twY = HBD:GetWorldCoordinatesFromZone(0.5, 0.5, toMapID)

    if fwX and fwY and twX and twY then
        local dist = Utils.Distance2D(fwX, fwY, twX, twY)
        local speed = Config.TRAVEL.SKYRIDING_SPEED or 100
        return math.max(5, dist / speed)  -- Minimum 5 seconds
    end

    return 120
end

function TravelPlanner:FindMapIDForLocation(locationName)
    if not locationName then return nil end
    locationName = strlower(locationName)

    if DXD.ZoneData then
        for continentName, continent in pairs(DXD.ZoneData) do
            if continent.children then
                for zoneName, zone in pairs(continent.children) do
                    if strlower(zoneName) == locationName or
                       strfind(strlower(zoneName), locationName, 1, true) then
                        return zone.mapID
                    end
                end
            end
        end
    end

    -- Fallback: WoW API lookup (limited range to avoid long iteration)
    for mapID = 1, 2700 do
        local info = C_Map.GetMapInfo(mapID)
        if info and info.name and strlower(info.name) == locationName then
            return mapID
        end
    end

    return nil
end

function TravelPlanner:GetCurrentRoute()
    return currentRoute, currentStep
end

function TravelPlanner:GetMethodName(method)
    return METHOD_NAMES[method] or "Travel"
end

function TravelPlanner:GetMethodIcon(method)
    return METHOD_ICONS[method] or ""
end

------------------------------------------------------------------------
-- ZONE CHANGE DETECTION
------------------------------------------------------------------------

function TravelPlanner:OnZoneChanged()
    if not currentRoute then return end

    local step = currentRoute.steps[currentStep]
    if step then
        local currentMap = C_Map.GetBestMapForUnit("player")
        if currentMap == step.toMapID then
            C_Timer.After(1, function()
                self:AdvanceStep()
            end)
        end
    end
end

------------------------------------------------------------------------
-- TEST
------------------------------------------------------------------------

function TravelPlanner:TestRoute()
    local fromMap = C_Map.GetBestMapForUnit("player")
    if not fromMap then
        DXD:Print("Cannot determine current location.")
        return
    end

    local _, faction = UnitFactionGroup("player")
    local testDest = faction == "Alliance" and 84 or 85
    local destInfo = C_Map.GetMapInfo(testDest)
    local destName = destInfo and destInfo.name or "Unknown"

    DXD:Print("Computing route to " .. destName .. "...")

    local route = self:FindRoute(fromMap, testDest)
    if route then
        if route.sameZone then
            DXD:Print("You're already in " .. destName .. "!")
        elseif #route.steps == 0 then
            DXD:Print("No route found.")
        else
            DXD:Print("Route found: " .. #route.steps .. " step(s)")
            for i, step in ipairs(route.steps) do
                DXD:Print("  " .. i .. ". " .. self:GetMethodIcon(step.method) .. " " .. step.name)
            end
            DXD:Print("  Total: " .. Utils.FormatETA(route.totalCost))
        end
    else
        DXD:Print("Could not compute route.")
    end
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function TravelPlanner:Initialize()
    BuildContinentLookup()
    DXD:Debug("TravelPlanner initialized")
end
