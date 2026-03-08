-- HereBeDragons-Pins-2.0 - Map pin management for HereBeDragons
-- Provides world map and minimap pin placement

local MAJOR, MINOR = "HereBeDragons-Pins-2.0", 12
local HBDPins, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not HBDPins then return end

local HBD = LibStub("HereBeDragons-2.0")

-- Pin storage
local worldmapPins = {}
local minimapPins = {}
local pinCount = 0

-- Minimap tracking
local minimapShape = "ROUND"
local minimapRotation = false
local minimapRadius = 75

local activeWorldPins = {}
local activeMinimapPins = {}

--- Add a pin to the world map
-- @param pin frame to use as pin
-- @param uiMapID the map to place the pin on
-- @param x map x coordinate (0-1)
-- @param y map y coordinate (0-1)
-- @param showInSubZones show on sub-zone maps too
function HBDPins:AddWorldMapIconMap(owner, pin, uiMapID, x, y, showInSubZones)
    if not pin or not uiMapID or not x or not y then return end
    pin.uiMapID = uiMapID
    pin.x = x
    pin.y = y
    pin.owner = owner
    pin.showInSubZones = showInSubZones

    activeWorldPins[pin] = true
end

--- Remove a world map pin
function HBDPins:RemoveWorldMapIcon(owner, pin)
    if pin then
        activeWorldPins[pin] = nil
        pin:Hide()
    end
end

--- Remove all world map pins for an owner
function HBDPins:RemoveAllWorldMapIcons(owner)
    for pin in pairs(activeWorldPins) do
        if pin.owner == owner then
            activeWorldPins[pin] = nil
            pin:Hide()
        end
    end
end

--- Add a pin to the minimap
-- @param pin frame to use as pin
-- @param uiMapID the map
-- @param x map x (0-1)
-- @param y map y (0-1)
function HBDPins:AddMinimapIconMap(owner, pin, uiMapID, x, y, showInSubZones, floatOnEdge)
    if not pin or not uiMapID or not x or not y then return end
    pin.uiMapID = uiMapID
    pin.x = x
    pin.y = y
    pin.owner = owner
    pin.floatOnEdge = floatOnEdge

    activeMinimapPins[pin] = true
end

--- Remove a minimap pin
function HBDPins:RemoveMinimapIcon(owner, pin)
    if pin then
        activeMinimapPins[pin] = nil
        pin:Hide()
    end
end

--- Remove all minimap pins for an owner
function HBDPins:RemoveAllMinimapIcons(owner)
    for pin in pairs(activeMinimapPins) do
        if pin.owner == owner then
            activeMinimapPins[pin] = nil
            pin:Hide()
        end
    end
end

--- Check if a pin is on the minimap edge
function HBDPins:IsMinimapIconOnEdge(pin)
    return pin and pin.onEdge
end
