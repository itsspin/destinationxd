------------------------------------------------------------------------
-- DestinationXD - QuestTracker.lua
-- Hook into WoW's quest supertracking system
-- Fixed: reliable beacon display for all quest types with retry logic
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local QuestTracker = {}
DXD:RegisterModule("QuestTracker", QuestTracker)

local Utils = DXD.Utils

-- State
local lastTrackedQuestID = nil
local isTrackingCorpse = false
local retryTimer = nil

------------------------------------------------------------------------
-- SUPERTRACKING INTEGRATION
------------------------------------------------------------------------

--- Called when SUPER_TRACKING_CHANGED fires
function QuestTracker:OnSuperTrackingChanged()
    if not DXD.state.initialized then return end

    -- Check for user waypoint first (higher priority)
    if C_SuperTrack.IsSuperTrackingUserWaypoint() then
        return
    end

    -- Check for supertracked quest
    local questID = C_SuperTrack.GetSuperTrackedQuestID()
    if questID and questID > 0 then
        self:TrackQuest(questID)
    elseif not C_SuperTrack.IsSuperTrackingAnything() then
        if DXD.state.targetType == "quest" or DXD.state.targetType == "dungeon" then
            DXD:ClearTarget()
        end
    end

    lastTrackedQuestID = questID
end

------------------------------------------------------------------------
-- QUEST TRACKING
------------------------------------------------------------------------

--- Try multiple methods to find quest location
local function FindQuestPosition(questID, mapID)
    -- Method 1: QuestPOI waypoint
    if QuestHasPOIInfo then
        local hasPOI = false
        pcall(function() hasPOI = QuestHasPOIInfo(questID) end)
        if hasPOI and C_QuestLog.GetNextWaypointForMap then
            local ok, x, y = pcall(C_QuestLog.GetNextWaypointForMap, questID, mapID)
            if ok and x and y and (x > 0 or y > 0) then
                return mapID, x, y
            end
        end
    end

    -- Method 2: C_QuestLog.GetNextWaypoint
    if C_QuestLog.GetNextWaypoint then
        local ok, wpMapID, wpX, wpY = pcall(C_QuestLog.GetNextWaypoint, questID)
        if ok and wpMapID and wpX and wpY and (wpX > 0 or wpY > 0) then
            return wpMapID, wpX, wpY
        end
    end

    -- Method 3: Try quest-specific map
    local questMapID
    if GetQuestUiMapID then
        local ok, result = pcall(GetQuestUiMapID, questID)
        if ok then questMapID = result end
    end
    if questMapID and questMapID > 0 and questMapID ~= mapID then
        if QuestHasPOIInfo and C_QuestLog.GetNextWaypointForMap then
            local ok, x, y = pcall(C_QuestLog.GetNextWaypointForMap, questID, questMapID)
            if ok and x and y and (x > 0 or y > 0) then
                return questMapID, x, y
            end
        end
        -- Fallback to center of quest map
        return questMapID, 0.5, 0.5
    end

    -- Method 4: Try task quest API (world quests, bonus objectives)
    if C_TaskQuest and C_TaskQuest.GetQuestLocation then
        local ok, x, y = pcall(C_TaskQuest.GetQuestLocation, questID, mapID)
        if ok and x and y and (x > 0 or y > 0) then
            return mapID, x, y
        end
    end

    return nil, nil, nil
end

--- Start tracking a quest objective
function QuestTracker:TrackQuest(questID)
    if not questID then return end

    -- Cancel any pending retry
    if retryTimer then
        retryTimer:Cancel()
        retryTimer = nil
    end

    -- Get quest info
    local questName = C_QuestLog.GetTitleForQuestID(questID)
    if not questName then
        questName = "Quest " .. questID
    end

    -- Get quest type for coloring
    local tagInfo = C_QuestLog.GetQuestTagInfo(questID)
    local targetType = "quest"
    if tagInfo then
        if tagInfo.tagID == Enum.QuestTag.Dungeon or tagInfo.tagID == Enum.QuestTag.Raid then
            targetType = "dungeon"
        end
    end

    -- Get the objective text
    local objectives = C_QuestLog.GetQuestObjectives(questID)
    local objectiveText = nil
    if objectives and #objectives > 0 then
        for _, obj in ipairs(objectives) do
            if not obj.finished then
                objectiveText = obj.text
                break
            end
        end
    end

    -- Try to get quest position
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end

    local foundMapID, foundX, foundY = FindQuestPosition(questID, mapID)

    if foundMapID and foundX and foundY then
        DXD:SetTarget(foundMapID, foundX, foundY, targetType, questName, objectiveText)
    else
        -- Position not available yet - happens when clicking quest before POI data loads
        DXD:Debug("Quest " .. questName .. " - position not ready, retrying...")

        -- Still mark as tracking so arrow works via C_Navigation
        DXD.state.hasTarget = true
        DXD.state.targetType = targetType
        DXD.state.targetName = questName
        DXD.state.targetDescription = objectiveText

        -- Notify modules so beacon at least tries to render
        for _, mod in pairs(DXD.modules) do
            if mod.OnTargetChanged then
                mod:OnTargetChanged()
            end
        end

        -- Retry up to 5 times with increasing delay
        local retryCount = 0
        local function RetryFindPosition()
            retryCount = retryCount + 1
            if retryCount > 5 then return end

            local rMapID = C_Map.GetBestMapForUnit("player")
            if not rMapID then return end

            local rFoundMap, rFoundX, rFoundY = FindQuestPosition(questID, rMapID)
            if rFoundMap and rFoundX and rFoundY then
                DXD:SetTarget(rFoundMap, rFoundX, rFoundY, targetType, questName, objectiveText)
                DXD:Debug("Quest position found on retry " .. retryCount)
            else
                retryTimer = C_Timer.NewTimer(0.4 * retryCount, RetryFindPosition)
            end
        end

        retryTimer = C_Timer.NewTimer(0.3, RetryFindPosition)
    end
end

------------------------------------------------------------------------
-- CORPSE TRACKING
------------------------------------------------------------------------

function QuestTracker:OnPlayerDead()
    isTrackingCorpse = true
    DXD:Debug("Player died, ready to track corpse")
end

function QuestTracker:OnPlayerAlive()
    if isTrackingCorpse then
        isTrackingCorpse = false
        if DXD.state.targetType == "corpse" then
            DXD:ClearTarget()
        end
    end
end

function QuestTracker:TrackCorpse()
    if not isTrackingCorpse then return end
    if not C_DeathInfo or not C_DeathInfo.GetCorpseMapPosition then return end

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end

    local ok, corpsePos = pcall(C_DeathInfo.GetCorpseMapPosition, mapID)
    if ok and corpsePos then
        local x, y = corpsePos:GetXY()
        if x and y and (x > 0 or y > 0) then
            DXD:SetTarget(mapID, x, y, "corpse", "Your Corpse", "Return to your body")
        end
    end
end

------------------------------------------------------------------------
-- UPDATE
------------------------------------------------------------------------

function QuestTracker:OnUpdate(elapsed)
    if isTrackingCorpse and not DXD.state.hasTarget then
        self:TrackCorpse()
    end

    -- Keep distance updated for quest tracking via C_Navigation
    if DXD.state.hasTarget and (DXD.state.targetType == "quest" or DXD.state.targetType == "dungeon") then
        if C_Navigation and C_Navigation.GetDistance then
            local navDist = C_Navigation.GetDistance()
            if navDist and navDist > 0 then
                DXD.state.navDistance = navDist
            end
        end
    end
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function QuestTracker:Initialize()
    if C_SuperTrack.IsSuperTrackingAnything() then
        C_Timer.After(0.5, function()
            self:OnSuperTrackingChanged()
        end)
    end

    DXD:Debug("QuestTracker initialized")
end
