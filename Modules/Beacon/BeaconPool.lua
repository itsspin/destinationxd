------------------------------------------------------------------------
-- DestinationXD - BeaconPool.lua
-- Object pooling for beacon visual elements
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local BeaconPool = {}
DXD:RegisterModule("BeaconPool", BeaconPool)

-- Pool storage
local framePools = {}

------------------------------------------------------------------------
-- POOL MANAGEMENT
------------------------------------------------------------------------

--- Get or create a pool for a specific frame type
local function GetPool(poolName, createFunc)
    if not framePools[poolName] then
        framePools[poolName] = {
            active = {},
            inactive = {},
            createFunc = createFunc,
            count = 0,
        }
    end
    return framePools[poolName]
end

--- Acquire a frame from the pool
function BeaconPool:Acquire(poolName, createFunc)
    local pool = GetPool(poolName, createFunc)

    local frame = table.remove(pool.inactive)
    if not frame then
        pool.count = pool.count + 1
        frame = pool.createFunc(pool.count)
    end

    pool.active[frame] = true
    return frame
end

--- Release a frame back to the pool
function BeaconPool:Release(poolName, frame)
    local pool = framePools[poolName]
    if not pool then return end

    pool.active[frame] = nil
    frame:Hide()
    frame:ClearAllPoints()
    table.insert(pool.inactive, frame)
end

--- Release all active frames in a pool
function BeaconPool:ReleaseAll(poolName)
    local pool = framePools[poolName]
    if not pool then return end

    for frame in pairs(pool.active) do
        frame:Hide()
        frame:ClearAllPoints()
        table.insert(pool.inactive, frame)
    end
    wipe(pool.active)
end

--- Get pool statistics
function BeaconPool:GetStats(poolName)
    local pool = framePools[poolName]
    if not pool then return 0, 0, 0 end

    local activeCount = 0
    for _ in pairs(pool.active) do
        activeCount = activeCount + 1
    end

    return activeCount, #pool.inactive, pool.count
end

------------------------------------------------------------------------
-- BEAM FRAME CREATORS
------------------------------------------------------------------------

--- Create a beam shaft texture frame
function BeaconPool.CreateBeamFrame(index)
    local frame = CreateFrame("Frame", "DXDBeam" .. index, UIParent)
    frame:SetFrameStrata("BACKGROUND")
    frame:SetFrameLevel(1)

    -- Main beam line (thin laser-like)
    local beam = frame:CreateTexture(nil, "ARTWORK")
    beam:SetTexture("Interface\\AddOns\\DestinationXD\\Media\\beacon_beam")
    beam:SetBlendMode("ADD")
    beam:SetAllPoints()
    frame.beam = beam

    -- Glow overlay (soft aura around the beam)
    local glow = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    glow:SetTexture("Interface\\AddOns\\DestinationXD\\Media\\beacon_glow")
    glow:SetBlendMode("ADD")
    glow:SetAlpha(0.4)
    frame.glow = glow

    frame:Hide()
    return frame
end

--- Create a base glow frame (ground marker)
function BeaconPool.CreateBaseGlowFrame(index)
    local frame = CreateFrame("Frame", "DXDBaseGlow" .. index, UIParent)
    frame:SetFrameStrata("BACKGROUND")
    frame:SetFrameLevel(0)

    local glow = frame:CreateTexture(nil, "ARTWORK")
    glow:SetTexture("Interface\\AddOns\\DestinationXD\\Media\\beacon_ring")
    glow:SetBlendMode("ADD")
    glow:SetAlpha(0.3)
    glow:SetAllPoints()
    frame.glow = glow

    frame:Hide()
    return frame
end

--- Create a firefly point frame (close range)
function BeaconPool.CreateFireflyFrame(index)
    local frame = CreateFrame("Frame", "DXDFirefly" .. index, UIParent)
    frame:SetFrameStrata("BACKGROUND")
    frame:SetFrameLevel(2)
    frame:SetSize(8, 8)

    local dot = frame:CreateTexture(nil, "ARTWORK")
    dot:SetTexture("Interface\\COMMON\\Indicator-Yellow")
    dot:SetBlendMode("ADD")
    dot:SetAllPoints()
    frame.dot = dot

    frame:Hide()
    return frame
end

--- Create an elevation chevron frame
function BeaconPool.CreateChevronFrame(index)
    local frame = CreateFrame("Frame", "DXDChevron" .. index, UIParent)
    frame:SetFrameStrata("BACKGROUND")
    frame:SetFrameLevel(3)
    frame:SetSize(8, 8)

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    text:SetPoint("CENTER")
    text:SetShadowColor(0, 0, 0, 0.5)
    text:SetShadowOffset(1, -1)
    frame.text = text

    frame:Hide()
    return frame
end

function BeaconPool:Initialize()
    -- Pre-warm pools
    DXD:Debug("BeaconPool initialized")
end
