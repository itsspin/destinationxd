------------------------------------------------------------------------
-- DestinationXD - Beacon.lua
-- No-op module: custom beam disabled, using WaypointUI addon instead.
-- Module kept as stub so other code referencing it doesn't error.
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local Beacon = {}
DXD:RegisterModule("Beacon", Beacon)

function Beacon:Initialize() end
function Beacon:OnUpdate() end
function Beacon:OnTargetChanged() end
function Beacon:OnTargetCleared() end
function Beacon:Show() end
function Beacon:Hide() end
function Beacon:TriggerArrival() end
