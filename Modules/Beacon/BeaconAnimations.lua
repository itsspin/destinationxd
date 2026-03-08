------------------------------------------------------------------------
-- DestinationXD - BeaconAnimations.lua
-- No-op module: custom beam disabled, using WaypointUI addon instead.
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local BeaconAnimations = {}
DXD:RegisterModule("BeaconAnimations", BeaconAnimations)

function BeaconAnimations:Initialize() end
function BeaconAnimations:OnUpdate() end
function BeaconAnimations:Reset() end
function BeaconAnimations:GetPulseAlpha() return 1 end
function BeaconAnimations:GetProximityAlpha() return 1 end
function BeaconAnimations:GetMorphProgress() return 0 end
function BeaconAnimations:GetBeamHeight() return 0 end
function BeaconAnimations:GetBeamWidth() return 0 end
function BeaconAnimations:GetGlowWidth() return 0 end
function BeaconAnimations:GetBobOffset() return 0 end
function BeaconAnimations:GetChevronOffset() return 0 end
function BeaconAnimations:GetIdleAlpha() return 1 end
function BeaconAnimations:UpdateMorph() end
function BeaconAnimations:UpdateIdleFade() end
function BeaconAnimations:TriggerArrival() end
function BeaconAnimations:UpdateArrival() return 1, 1, false end
function BeaconAnimations:IsArrivalPlaying() return false end
