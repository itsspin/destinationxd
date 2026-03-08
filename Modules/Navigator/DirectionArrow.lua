------------------------------------------------------------------------
-- DestinationXD - DirectionArrow.lua
-- No-op module: custom arrow disabled, using WaypointUI addon instead.
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local DirectionArrow = {}
DXD:RegisterModule("DirectionArrow", DirectionArrow)

function DirectionArrow:Initialize() end
function DirectionArrow:OnUpdate() end
function DirectionArrow:OnTargetChanged() end
function DirectionArrow:OnTargetCleared() end
