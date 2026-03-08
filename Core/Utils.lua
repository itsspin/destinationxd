------------------------------------------------------------------------
-- DestinationXD - Utils.lua
-- Math helpers, color utilities, throttle functions, easing
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...
DXD.Utils = {}
local Utils = DXD.Utils

-- Lua standard references (avoid global lookups in hot paths)
local math_sqrt = math.sqrt
local math_sin = math.sin
local math_cos = math.cos
local math_atan2 = math.atan2
local math_abs = math.abs
local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local math_pi = math.pi
local math_huge = math.huge

local PI2 = math_pi * 2
local DEG_TO_RAD = math_pi / 180
local RAD_TO_DEG = 180 / math_pi

------------------------------------------------------------------------
-- MATH HELPERS
------------------------------------------------------------------------

--- 2D distance between two points
function Utils.Distance2D(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math_sqrt(dx * dx + dy * dy)
end

--- 3D distance between two points
function Utils.Distance3D(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return math_sqrt(dx * dx + dy * dy + dz * dz)
end

--- Bearing angle from point A to point B (in radians, 0 = north, clockwise)
function Utils.Bearing(x1, y1, x2, y2)
    local angle = math_atan2(x2 - x1, y2 - y1)
    if angle < 0 then angle = angle + PI2 end
    return angle
end

--- Normalize angle to [0, 2*PI)
function Utils.NormalizeAngle(angle)
    angle = angle % PI2
    if angle < 0 then angle = angle + PI2 end
    return angle
end

--- Shortest signed angle difference between two angles (radians)
function Utils.AngleDelta(from, to)
    local delta = (to - from) % PI2
    if delta > math_pi then delta = delta - PI2 end
    return delta
end

--- Clamp a value between min and max
function Utils.Clamp(value, minVal, maxVal)
    if value < minVal then return minVal end
    if value > maxVal then return maxVal end
    return value
end

--- Linear interpolation
function Utils.Lerp(a, b, t)
    return a + (b - a) * t
end

--- Smooth-step interpolation (Hermite)
function Utils.SmoothStep(a, b, t)
    t = Utils.Clamp(t, 0, 1)
    t = t * t * (3 - 2 * t)
    return a + (b - a) * t
end

--- Map a value from one range to another
function Utils.Remap(value, inMin, inMax, outMin, outMax)
    if inMax == inMin then return (outMin + outMax) * 0.5 end
    local t = (value - inMin) / (inMax - inMin)
    t = Utils.Clamp(t, 0, 1)
    return outMin + (outMax - outMin) * t
end

--- Convert yards to a display string
function Utils.FormatDistance(yards)
    if not yards then return "?" end
    if yards < 1 then return "<1y" end
    return math_floor(yards + 0.5) .. "y"
end

--- Format time estimate in seconds to display string
function Utils.FormatETA(seconds)
    if not seconds or seconds < 0 then return "" end
    if seconds < 60 then
        return "~" .. math_floor(seconds + 0.5) .. "s"
    elseif seconds < 3600 then
        local mins = math_floor(seconds / 60)
        local secs = math_floor(seconds % 60)
        if secs > 0 then
            return "~" .. mins .. "m " .. secs .. "s"
        end
        return "~" .. mins .. "m"
    else
        local hours = math_floor(seconds / 3600)
        local mins = math_floor((seconds % 3600) / 60)
        return "~" .. hours .. "h " .. mins .. "m"
    end
end

------------------------------------------------------------------------
-- EASING FUNCTIONS
------------------------------------------------------------------------

--- Cubic ease-in-out (the default easing for all DestinationXD animations)
function Utils.EaseInOutCubic(t)
    t = Utils.Clamp(t, 0, 1)
    if t < 0.5 then
        return 4 * t * t * t
    else
        local f = -2 * t + 2
        return 1 - (f * f * f) / 2
    end
end

--- Ease-out cubic
function Utils.EaseOutCubic(t)
    t = Utils.Clamp(t, 0, 1)
    local f = 1 - t
    return 1 - f * f * f
end

--- Ease-in cubic
function Utils.EaseInCubic(t)
    t = Utils.Clamp(t, 0, 1)
    return t * t * t
end

--- Sine wave oscillation (for beacon breathing)
function Utils.SineWave(time, period, minVal, maxVal)
    local t = (time % period) / period
    local wave = (math_sin(t * PI2) + 1) / 2  -- 0 to 1
    return minVal + wave * (maxVal - minVal)
end

------------------------------------------------------------------------
-- COLOR UTILITIES
------------------------------------------------------------------------

--- Create a color table
function Utils.Color(r, g, b, a)
    return { r = r, g = g, b = b, a = a or 1 }
end

--- Lerp between two colors
function Utils.LerpColor(c1, c2, t)
    t = Utils.Clamp(t, 0, 1)
    return {
        r = c1.r + (c2.r - c1.r) * t,
        g = c1.g + (c2.g - c1.g) * t,
        b = c1.b + (c2.b - c1.b) * t,
        a = c1.a + (c2.a - c1.a) * t,
    }
end

--- Apply color to a font string
function Utils.ApplyColor(fontString, color)
    if fontString and color then
        fontString:SetTextColor(color.r, color.g, color.b, color.a or 1)
    end
end

--- Apply color to a texture
function Utils.ApplyTextureColor(texture, color)
    if texture and color then
        texture:SetVertexColor(color.r, color.g, color.b, color.a or 1)
    end
end

------------------------------------------------------------------------
-- THROTTLE SYSTEM
------------------------------------------------------------------------

--- Create a throttled function that only executes at a specified interval
-- @param interval seconds between executions
-- @param func the function to throttle
-- @return wrapped function
function Utils.Throttle(interval, func)
    local lastTime = 0
    return function(...)
        local now = GetTime()
        if now - lastTime >= interval then
            lastTime = now
            return func(...)
        end
    end
end

--- Create an accumulator-based throttle (better for OnUpdate)
-- Returns elapsed time only when threshold is crossed
function Utils.CreateAccumulator(interval)
    local accumulated = 0
    return {
        ShouldUpdate = function(self, elapsed)
            accumulated = accumulated + elapsed
            if accumulated >= interval then
                accumulated = accumulated - interval
                return true
            end
            return false
        end,
        Reset = function(self)
            accumulated = 0
        end,
    }
end

------------------------------------------------------------------------
-- FRAME UTILITIES
------------------------------------------------------------------------

--- Set standard font with shadow per design specs
function Utils.SetFont(fontString, size, alpha)
    fontString:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
    fontString:SetShadowColor(0, 0, 0, 0.5)
    fontString:SetShadowOffset(1, -1)
    if alpha then
        fontString:SetAlpha(alpha)
    end
end

--- Safe show with fade-in (custom implementation, UIFrameFade was removed in 10.x)
function Utils.FadeIn(frame, duration, targetAlpha)
    if not frame then return end
    targetAlpha = targetAlpha or 1
    duration = duration or 0.25

    frame:Show()
    local startAlpha = frame:GetAlpha()
    local startTime = GetTime()

    -- Cancel any existing fade
    if frame.dxdFadeTicker then
        frame.dxdFadeTicker:Cancel()
    end

    frame.dxdFadeTicker = C_Timer.NewTicker(0.016, function(ticker)
        local elapsed = GetTime() - startTime
        local progress = math.min(1, elapsed / duration)
        local easedProgress = Utils.EaseOutCubic(progress)
        frame:SetAlpha(startAlpha + (targetAlpha - startAlpha) * easedProgress)
        if progress >= 1 then
            ticker:Cancel()
            frame.dxdFadeTicker = nil
        end
    end)
end

--- Safe hide with fade-out (custom implementation, UIFrameFade was removed in 10.x)
function Utils.FadeOut(frame, duration, finishedFunc)
    if not frame then return end
    duration = duration or 0.4

    local startAlpha = frame:GetAlpha()
    local startTime = GetTime()

    if frame.dxdFadeTicker then
        frame.dxdFadeTicker:Cancel()
    end

    frame.dxdFadeTicker = C_Timer.NewTicker(0.016, function(ticker)
        local elapsed = GetTime() - startTime
        local progress = math.min(1, elapsed / duration)
        local easedProgress = Utils.EaseInCubic(progress)
        frame:SetAlpha(startAlpha * (1 - easedProgress))
        if progress >= 1 then
            ticker:Cancel()
            frame.dxdFadeTicker = nil
            frame:Hide()
            frame:SetAlpha(0)
            if finishedFunc then finishedFunc() end
        end
    end)
end

------------------------------------------------------------------------
-- TABLE UTILITIES
------------------------------------------------------------------------

--- Deep copy a table
function Utils.DeepCopy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        if type(v) == "table" then
            copy[k] = Utils.DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

--- Merge table b into table a (b overrides a)
function Utils.MergeDefaults(a, b)
    for k, v in pairs(b) do
        if type(v) == "table" and type(a[k]) == "table" then
            Utils.MergeDefaults(a[k], v)
        elseif a[k] == nil then
            a[k] = v
        end
    end
    return a
end

------------------------------------------------------------------------
-- WORLD-TO-SCREEN PROJECTION
------------------------------------------------------------------------

--- Project target position to screen coordinates
-- WoW has NO legitimate WorldToScreen API for addons.
-- We use C_Navigation.GetFrame() to get the screen position of the
-- supertracked waypoint, which is the ONLY sanctioned approach.
-- For targets not using supertracking, we fall back to a bearing-based
-- HUD approach (arrow + distance only, no screen-space beam).
--
-- @param worldX world X coordinate (unused for nav frame approach)
-- @param worldY world Y coordinate (unused for nav frame approach)
-- @param worldZ world Z coordinate (unused for nav frame approach)
-- @return screenX, screenY, onScreen
function Utils.WorldToScreen(worldX, worldY, worldZ)
    -- Primary method: use C_Navigation frame for supertracked waypoints
    if C_Navigation and C_Navigation.HasValidScreenPosition and C_Navigation.HasValidScreenPosition() then
        local navFrame = C_Navigation.GetFrame()
        if navFrame and navFrame:IsShown() then
            local cx, cy = navFrame:GetCenter()
            if cx and cy then
                local wasClamped = C_Navigation.WasClampedToScreen()
                return cx, cy, not wasClamped
            end
        end
    end

    -- Fallback: bearing-based screen position estimation
    -- This provides a directional indicator even when C_Navigation isn't active
    local py, px, pz, instanceID = UnitPosition("player")
    if not px or not py or not worldX or not worldY then return nil, nil, false end

    local facing = GetPlayerFacing()
    if not facing then return nil, nil, false end

    -- Calculate relative position
    local dx = worldX - px
    local dy = worldY - py

    -- Rotate relative to player facing
    local cosF = math_cos(-facing)
    local sinF = math_sin(-facing)
    local relX = dx * cosF - dy * sinF
    local relY = dx * sinF + dy * cosF

    -- Check if point is roughly in front of player
    if relY < 1 then return nil, nil, false end

    -- Estimate screen position using angular offset from center
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()

    -- Horizontal angle from center of view
    local hAngle = math_atan2(relX, relY)
    -- Approximate FOV of ~90 degrees
    local hFov = math_pi / 2
    local screenX = screenWidth * 0.5 + (hAngle / hFov) * screenWidth * 0.5

    -- Vertical position: place at a fixed height (we can't know true screen Y)
    -- Use distance-based height: closer = lower on screen, farther = higher
    local dist = math_sqrt(relX * relX + relY * relY)
    local screenY = screenHeight * 0.35 + Utils.Remap(dist, 5, 200, screenHeight * 0.15, 0)

    local margin = 50
    local onScreen = screenX >= -margin and screenX <= screenWidth + margin
                     and screenY >= -margin and screenY <= screenHeight + margin

    return screenX, screenY, onScreen
end

------------------------------------------------------------------------
-- MOVEMENT SPEED ESTIMATION
------------------------------------------------------------------------

local lastPos = {}
local speedSamples = {}
local MAX_SPEED_SAMPLES = 10
local currentSpeed = 0

--- Update speed estimate (call from OnUpdate)
function Utils.UpdateSpeed()
    -- UnitPosition returns (posY, posX, posZ, instanceID) - note swapped axes!
    local posY, posX, posZ = UnitPosition("player")
    if not posX or not posY then return 0 end
    local px, py = posX, posY

    local now = GetTime()
    if lastPos.x and lastPos.time then
        local dt = now - lastPos.time
        if dt > 0 and dt < 1 then
            local dist = Utils.Distance2D(lastPos.x, lastPos.y, px, py)
            local speed = dist / dt

            -- Add to samples ring buffer
            table.insert(speedSamples, speed)
            if #speedSamples > MAX_SPEED_SAMPLES then
                table.remove(speedSamples, 1)
            end

            -- Average
            local sum = 0
            for _, s in ipairs(speedSamples) do
                sum = sum + s
            end
            currentSpeed = sum / #speedSamples
        end
    end

    lastPos.x = px
    lastPos.y = py
    lastPos.z = pz
    lastPos.time = now
    return currentSpeed
end

--- Get current estimated movement speed in yards/sec
function Utils.GetSpeed()
    return currentSpeed
end

--- Estimate time to reach a distance at current speed
function Utils.EstimateETA(distanceYards)
    local speed = currentSpeed
    if speed < 0.5 then return nil end  -- Standing still
    return distanceYards / speed
end
