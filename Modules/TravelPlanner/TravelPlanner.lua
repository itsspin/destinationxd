------------------------------------------------------------------------
-- DestinationXD - TravelPlanner.lua
-- Smart route calculation engine using Dijkstra's algorithm
-- Considers portals, hearthstones, flight paths, walking/flying
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
    [METHOD.WALK_FLY]      = "\226\156\136",  -- ✈ (walk/fly icon)
    [METHOD.FLIGHT_PATH]   = "\226\156\136",  -- ✈
    [METHOD.PORTAL]        = "\226\156\168",  -- ✨ (portal icon)
    [METHOD.HEARTHSTONE]   = "\226\153\165",  -- ♥ (hearthstone icon)
    [METHOD.BOAT_ZEPPELIN] = "\226\155\181",  -- ⛵ (boat icon)
}

-- Route state
local currentRoute = nil
local currentStep = 0

------------------------------------------------------------------------
-- GRAPH BUILDING
------------------------------------------------------------------------

--- Build a travel graph for pathfinding
-- Nodes = map IDs, Edges = travel methods with time costs
local function BuildGraph(fromMapID, toMapID)
    local graph = {}  -- [mapID] = { edges = { {to, cost, method, details} } }
    local portalDB = DXD:GetModule("PortalDatabase")
    local flightDB = DXD:GetModule("FlightPathGraph")

    if not portalDB then return graph end

    -- Add portal edges
    if DXD.PortalData then
        for _, portal in ipairs(DXD.PortalData) do
            local src = portal.srcMapID
            local dst = portal.dstMapID

            if src and dst then
                -- Check faction
                local faction = portal.faction
                local _, playerFaction = UnitFactionGroup("player")
                if not faction or faction == "Both" or faction == playerFaction then
                    if not graph[src] then
                        graph[src] = { edges = {} }
                    end
                    table.insert(graph[src].edges, {
                        to = dst,
                        cost = portal.travelTime or Config.TRAVEL.PORTAL_CAST_TIME,
                        method = METHOD.PORTAL,
                        details = portal,
                        name = portal.name or "Portal",
                    })
                end
            end
        end
    end

    -- Add hearthstone edge if relevant
    if DXD.db.considerHearthstoneCooldown then
        local hsLocation = GetBindLocation()
        if hsLocation then
            -- Use modern API if available, fallback to legacy
            local hsCooldown = 1
            if C_Container and C_Container.GetItemCooldown then
                hsCooldown = C_Container.GetItemCooldown(6948) or 0
            elseif GetItemCooldown then
                hsCooldown = GetItemCooldown(6948) or 0
            end
            local hsReady = (hsCooldown == 0)
            if hsReady then
                -- Find the hearthstone destination map
                -- This is approximate since GetBindLocation returns a string
                local hsMapID = TravelPlanner:FindMapIDForLocation(hsLocation)
                if hsMapID and fromMapID then
                    if not graph[fromMapID] then
                        graph[fromMapID] = { edges = {} }
                    end
                    table.insert(graph[fromMapID].edges, {
                        to = hsMapID,
                        cost = Config.TRAVEL.HS_CAST_TIME,
                        method = METHOD.HEARTHSTONE,
                        name = "Hearthstone to " .. hsLocation,
                    })
                end
            end
        end
    end

    return graph
end

------------------------------------------------------------------------
-- DIJKSTRA'S PATHFINDING
------------------------------------------------------------------------

--- Find shortest path from source to destination
-- @param fromMapID starting map
-- @param toMapID destination map
-- @return route table { steps = { {mapID, method, name, cost} }, totalCost }
function TravelPlanner:FindRoute(fromMapID, toMapID)
    if not fromMapID or not toMapID then return nil end
    if fromMapID == toMapID then
        return { steps = {}, totalCost = 0, sameZone = true }
    end

    local graph = BuildGraph(fromMapID, toMapID)

    -- Dijkstra's algorithm
    local dist = {}     -- [mapID] = shortest distance
    local prev = {}     -- [mapID] = { from, edge }
    local visited = {}  -- [mapID] = true
    local queue = {}    -- priority queue (simple table-based)

    dist[fromMapID] = 0
    table.insert(queue, { mapID = fromMapID, cost = 0 })

    while #queue > 0 do
        -- Find minimum cost node
        local minIdx = 1
        for i = 2, #queue do
            if queue[i].cost < queue[minIdx].cost then
                minIdx = i
            end
        end
        local current = table.remove(queue, minIdx)
        local u = current.mapID

        if visited[u] then
            -- Skip if already visited with shorter path
        else
            visited[u] = true

            -- Found destination
            if u == toMapID then break end

            -- Process edges
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
    if not prev[toMapID] and fromMapID ~= toMapID then
        -- No path found via portals; suggest flying directly
        return {
            steps = {
                {
                    fromMapID = fromMapID,
                    toMapID = toMapID,
                    method = METHOD.WALK_FLY,
                    name = "Fly to destination",
                    cost = self:EstimateFlyTime(fromMapID, toMapID),
                }
            },
            totalCost = self:EstimateFlyTime(fromMapID, toMapID),
            directFlight = true,
        }
    end

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

------------------------------------------------------------------------
-- ROUTE EXECUTION
------------------------------------------------------------------------

--- Start navigating a route
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

    -- Set waypoint to the step's starting location
    if step.details and step.details.srcX and step.details.srcY then
        DXD:SetTarget(step.details.srcMapID, step.details.srcX, step.details.srcY,
            "travel", step.name,
            "Step " .. stepIndex .. "/" .. #currentRoute.steps)
    elseif step.fromMapID then
        -- Navigate to the zone center as a fallback
        DXD:SetTarget(step.fromMapID, 0.5, 0.5, "travel", step.name,
            "Step " .. stepIndex .. "/" .. #currentRoute.steps)
    end

    DXD:Print("Step " .. stepIndex .. ": " .. (METHOD_ICONS[step.method] or "") .. " " .. step.name)
end

--- Advance to the next step
function TravelPlanner:AdvanceStep()
    if not currentRoute then return end

    local nextStep = currentStep + 1
    if nextStep > #currentRoute.steps then
        -- Route complete
        self:CompleteRoute()
    else
        self:NavigateToStep(nextStep)
    end
end

--- Complete the route
function TravelPlanner:CompleteRoute()
    DXD:Print("Route complete! You've arrived.")
    currentRoute = nil
    currentStep = 0
    DXD.state.travelRoute = nil
    DXD.state.travelRouteStep = 0
end

--- Cancel the current route
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

--- Estimate fly time between two maps
function TravelPlanner:EstimateFlyTime(fromMapID, toMapID)
    -- Very rough estimate based on map distance
    local HBD = DXD.HBD
    local fromX, fromY = 0.5, 0.5  -- Center of map
    local toX, toY = 0.5, 0.5

    local fwX, fwY = HBD:GetWorldCoordinatesFromZone(fromX, fromY, fromMapID)
    local twX, twY = HBD:GetWorldCoordinatesFromZone(toX, toY, toMapID)

    if fwX and fwY and twX and twY then
        local dist = Utils.Distance2D(fwX, fwY, twX, twY)
        return dist / Config.TRAVEL.SKYRIDING_SPEED
    end

    return 120  -- Default 2 minutes for unknown distances
end

--- Find map ID from a location name string
function TravelPlanner:FindMapIDForLocation(locationName)
    if not locationName then return nil end
    locationName = strlower(locationName)

    -- Search zone data
    if DXD.ZoneData then
        for continentName, continent in pairs(DXD.ZoneData) do
            if continent.children then
                for zoneName, zone in pairs(continent.children) do
                    if strlower(zoneName) == locationName or
                       (zone.altNames and tContains(zone.altNames, locationName)) then
                        return zone.mapID
                    end
                end
            end
        end
    end

    -- Fallback: iterate WoW maps
    for mapID = 1, 2500 do
        local info = C_Map.GetMapInfo(mapID)
        if info and info.name and strlower(info.name) == locationName then
            return mapID
        end
    end

    return nil
end

--- Get the current route info
function TravelPlanner:GetCurrentRoute()
    return currentRoute, currentStep
end

--- Get method display info
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

    -- Check if we've arrived at the current step's destination
    local step = currentRoute.steps[currentStep]
    if step then
        local currentMap = C_Map.GetBestMapForUnit("player")
        if currentMap == step.toMapID then
            -- Arrived at this step's destination, advance
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

    -- Try to route to Stormwind (84) or Orgrimmar (85) as test
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
    DXD:Debug("TravelPlanner initialized")
end
