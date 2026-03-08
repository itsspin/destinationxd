------------------------------------------------------------------------
-- DestinationXD - QuestTracker.lua
-- Hook into WoW's quest supertracking system
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local QuestTracker = {}
DXD:RegisterModule("QuestTracker", QuestTracker)

local Utils = DXD.Utils

-- State
local lastTrackedQuestID = nil
local isTrackingCorpse = false

------------------------------------------------------------------------
-- SUPERTRACKING INTEGRATION
------------------------------------------------------------------------

--- Called when SUPER_TRACKING_CHANGED fires
function QuestTracker:OnSuperTrackingChanged()
    if not DXD.state.initialized then return end

    -- Check for user waypoint first (higher priority)
    if C_SuperTrack.IsSuperTrackingUserWaypoint() then
        -- WaypointTracker handles this
        return
    end

    -- Check for supertracked quest
    local questID = C_SuperTrack.GetSuperTrackedQuestID()
    if questID and questID > 0 then
        self:TrackQuest(questID)
    elseif not C_SuperTrack.IsSuperTrackingAnything() then
        -- Nothing is being tracked
        if DXD.state.targetType == "quest" then
            DXD:ClearTarget()
        end
    end

    lastTrackedQuestID = questID
end

------------------------------------------------------------------------
-- QUEST TRACKING
------------------------------------------------------------------------

--- Start tracking a quest objective
function QuestTracker:TrackQuest(questID)
    if not questID then return end

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

    -- Try to get quest POI position
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end

    -- Get quest waypoint from the navigation system
    -- The supertracking system in WoW already computes waypoint positions
    -- We rely on C_Navigation.GetDistance() for distance,
    -- and quest POI data for position

    -- Try QuestPOI data
    local questMapID = GetQuestUiMapID and GetQuestUiMapID(questID)
    if questMapID and questMapID > 0 then
        mapID = questMapID
    end

    -- Try to get the quest waypoint position from the map pin
    local waypoints = C_QuestLog.GetQuestObjectives(questID)
    local targetSet = false

    -- Use C_TaskQuest or C_QuestLog to find quest location
    if QuestHasPOIInfo and QuestHasPOIInfo(questID) then
        local x, y = C_QuestLog.GetNextWaypointForMap(questID, mapID)
        if x and y then
            DXD:SetTarget(mapID, x, y, targetType, questName, objectiveText)
            targetSet = true
        end
    end

    -- Fallback: try getting next waypoint (returns mapID, x, y)
    if not targetSet and C_QuestLog.GetNextWaypoint then
        local wpMapID, wpX, wpY = C_QuestLog.GetNextWaypoint(questID)
        if wpMapID and wpX and wpY then
            DXD:SetTarget(wpMapID, wpX, wpY, targetType, questName, objectiveText)
            targetSet = true
        end
    end

    -- If we can't find a specific position, still set up tracking
    -- The beacon won't render, but distance/arrow will work via C_Navigation
    if not targetSet then
        DXD:Debug("Quest tracked but no POI position found for: " .. questName)
        -- We can still use C_Navigation.GetDistance() for distance display
        DXD.state.hasTarget = true
        DXD.state.targetType = targetType
        DXD.state.targetName = questName
        DXD.state.targetDescription = objectiveText
    end
end

------------------------------------------------------------------------
-- CORPSE TRACKING
------------------------------------------------------------------------

function QuestTracker:OnPlayerDead()
    isTrackingCorpse = true
    -- Will be handled when corpse location is available
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

--- Track the player's corpse (called after release)
function QuestTracker:TrackCorpse()
    if not isTrackingCorpse then return end

    local corpseMapID = C_DeathInfo.GetCorpseMapPosition(C_Map.GetBestMapForUnit("player"))
    if corpseMapID then
        local x, y = corpseMapID:GetXY()
        if x and y and (x > 0 or y > 0) then
            local mapID = C_Map.GetBestMapForUnit("player")
            DXD:SetTarget(mapID, x, y, "corpse", "Your Corpse", "Return to your body")
        end
    end
end

------------------------------------------------------------------------
-- UPDATE
------------------------------------------------------------------------

function QuestTracker:OnUpdate(elapsed)
    -- Check for corpse tracking
    if isTrackingCorpse and not DXD.state.hasTarget then
        self:TrackCorpse()
    end

    -- Update quest distance from C_Navigation if we're quest tracking
    if DXD.state.hasTarget and DXD.state.targetType == "quest" then
        if C_Navigation and C_Navigation.GetDistance then
            local navDist = C_Navigation.GetDistance()
            if navDist and navDist > 0 then
                -- Use nav distance as a reference for our calculations
                DXD.state.navDistance = navDist
            end
        end
    end
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function QuestTracker:Initialize()
    -- Check if something is already being tracked
    if C_SuperTrack.IsSuperTrackingAnything() then
        C_Timer.After(0.5, function()
            self:OnSuperTrackingChanged()
        end)
    end

    DXD:Debug("QuestTracker initialized")
end
