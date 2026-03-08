------------------------------------------------------------------------
-- DestinationXD - Widgets.lua
-- Reusable UI components following radical minimalism design
-- No borders, no backgrounds (almost), text IS the button
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

DXD.Widgets = {}
local Widgets = DXD.Widgets

local Config = DXD.Config
local Utils = DXD.Utils

------------------------------------------------------------------------
-- TEXT BUTTON (text-only, hover = opacity change)
------------------------------------------------------------------------

--- Create a minimal text button
-- @param parent parent frame
-- @param text button label
-- @param size font size
-- @param onClick click handler
-- @return button frame
function Widgets.CreateTextButton(parent, text, size, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(100, 20)

    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", size or Config.FONT_SIZES.HEADER, "OUTLINE")
    label:SetShadowColor(0, 0, 0, 0.5)
    label:SetShadowOffset(1, -1)
    label:SetPoint("CENTER")
    label:SetText(text)

    local primary = Config.COLORS.TEXT_PRIMARY
    local secondary = Config.COLORS.TEXT_SECONDARY
    label:SetTextColor(secondary.r, secondary.g, secondary.b, secondary.a)

    -- Underline (hidden, appears on hover)
    local underline = btn:CreateTexture(nil, "ARTWORK")
    underline:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    underline:SetSize(1, 1)
    underline:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -1)
    underline:SetPoint("TOPRIGHT", label, "BOTTOMRIGHT", 0, -1)
    underline:SetVertexColor(primary.r, primary.g, primary.b, 0)
    underline:SetHeight(1)
    btn.underline = underline

    -- Auto-size to text
    btn:SetWidth(label:GetStringWidth() + 16)
    btn:SetHeight(size + 8)

    -- Hover effect
    btn:SetScript("OnEnter", function(self)
        label:SetTextColor(primary.r, primary.g, primary.b, primary.a)
        underline:SetVertexColor(primary.r, primary.g, primary.b, 0.3)
    end)

    btn:SetScript("OnLeave", function(self)
        label:SetTextColor(secondary.r, secondary.g, secondary.b, secondary.a)
        underline:SetVertexColor(primary.r, primary.g, primary.b, 0)
    end)

    -- Click with subtle scale pulse
    btn:SetScript("OnMouseDown", function(self)
        label:SetPoint("CENTER", 0, -1)
    end)

    btn:SetScript("OnMouseUp", function(self)
        label:SetPoint("CENTER", 0, 0)
    end)

    if onClick then
        btn:SetScript("OnClick", onClick)
    end

    btn.label = label
    return btn
end

------------------------------------------------------------------------
-- CLOSE BUTTON (just an × character)
------------------------------------------------------------------------

function Widgets.CreateCloseButton(parent, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(20, 20)

    local text = btn:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    text:SetShadowColor(0, 0, 0, 0.5)
    text:SetShadowOffset(1, -1)
    text:SetPoint("CENTER")
    text:SetText("\195\151")  -- ×

    local tertiary = Config.COLORS.TEXT_TERTIARY
    local primary = Config.COLORS.TEXT_PRIMARY
    text:SetTextColor(tertiary.r, tertiary.g, tertiary.b, tertiary.a)

    btn:SetScript("OnEnter", function(self)
        text:SetTextColor(primary.r, primary.g, primary.b, primary.a)
    end)

    btn:SetScript("OnLeave", function(self)
        text:SetTextColor(tertiary.r, tertiary.g, tertiary.b, tertiary.a)
    end)

    btn:SetScript("OnClick", onClick or function(self)
        self:GetParent():Hide()
    end)

    return btn
end

------------------------------------------------------------------------
-- SCROLL FRAME (invisible scrollbar, thin indicator)
------------------------------------------------------------------------

function Widgets.CreateScrollFrame(parent, width, height)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, height)

    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(width, height)
    scrollFrame:SetPoint("TOPLEFT")

    -- Hide the default scrollbar elements
    if scrollFrame.ScrollBar then
        scrollFrame.ScrollBar:Hide()
        scrollFrame.ScrollBar:SetAlpha(0)
    end

    -- Content frame
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(width, 1)  -- Height will be set dynamically
    scrollFrame:SetScrollChild(content)

    -- Thin scroll indicator (2px line on right edge)
    local indicator = container:CreateTexture(nil, "OVERLAY")
    indicator:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    indicator:SetWidth(2)
    indicator:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)

    local primary = Config.COLORS.TEXT_PRIMARY
    indicator:SetVertexColor(primary.r, primary.g, primary.b, 0)
    indicator:Hide()

    container.scrollFrame = scrollFrame
    container.content = content
    container.indicator = indicator

    -- Show indicator while scrolling, fade after 1s
    local indicatorTimer = nil
    scrollFrame:SetScript("OnScrollRangeChanged", function(self, xRange, yRange)
        if yRange > 0 then
            local scrollPos = self:GetVerticalScroll()
            local indicatorHeight = math.max(20, height * (height / (yRange + height)))
            local indicatorPos = (scrollPos / yRange) * (height - indicatorHeight)

            indicator:SetHeight(indicatorHeight)
            indicator:ClearAllPoints()
            indicator:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, -indicatorPos)
        end
    end)

    -- Enable mouse wheel scrolling
    container:EnableMouseWheel(true)
    container:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollFrame:GetVerticalScroll()
        local range = scrollFrame:GetVerticalScrollRange()
        local step = 30

        local newScroll = current - delta * step
        newScroll = math.max(0, math.min(newScroll, range))
        scrollFrame:SetVerticalScroll(newScroll)

        -- Show indicator
        if range > 0 then
            local indicatorHeight = math.max(20, height * (height / (range + height)))
            local indicatorPos = (newScroll / range) * (height - indicatorHeight)
            indicator:SetHeight(indicatorHeight)
            indicator:ClearAllPoints()
            indicator:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, -indicatorPos)
            indicator:SetVertexColor(primary.r, primary.g, primary.b, 0.3)
            indicator:Show()

            -- Fade indicator after 1s
            if indicatorTimer then
                indicatorTimer:Cancel()
            end
            indicatorTimer = C_Timer.NewTimer(1, function()
                indicator:SetVertexColor(primary.r, primary.g, primary.b, 0)
            end)
        end
    end)

    return container
end

------------------------------------------------------------------------
-- CHECKBOX (minimal toggle)
------------------------------------------------------------------------

function Widgets.CreateCheckbox(parent, text, dbKey, onChange)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(200, 20)

    -- Check indicator (small dot)
    local check = frame:CreateTexture(nil, "ARTWORK")
    check:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    check:SetSize(8, 8)
    check:SetPoint("LEFT", 0, 0)

    local primary = Config.COLORS.TEXT_PRIMARY
    local secondary = Config.COLORS.TEXT_SECONDARY
    local tertiary = Config.COLORS.TEXT_TERTIARY

    -- Label
    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.ZONE_NAME, "OUTLINE")
    label:SetShadowColor(0, 0, 0, 0.5)
    label:SetShadowOffset(1, -1)
    label:SetPoint("LEFT", check, "RIGHT", 8, 0)
    label:SetText(text)

    -- State
    local function UpdateVisuals()
        local checked = DXD.db[dbKey]
        if checked then
            check:SetVertexColor(Config.COLORS.ELEV_LEVEL.r, Config.COLORS.ELEV_LEVEL.g,
                Config.COLORS.ELEV_LEVEL.b, 0.8)
            label:SetTextColor(primary.r, primary.g, primary.b, primary.a)
        else
            check:SetVertexColor(tertiary.r, tertiary.g, tertiary.b, tertiary.a)
            label:SetTextColor(secondary.r, secondary.g, secondary.b, secondary.a)
        end
    end

    -- Click area
    local clickArea = CreateFrame("Button", nil, frame)
    clickArea:SetAllPoints(frame)
    clickArea:SetScript("OnClick", function()
        DXD.db[dbKey] = not DXD.db[dbKey]
        UpdateVisuals()
        if onChange then onChange(DXD.db[dbKey]) end
    end)

    clickArea:SetScript("OnEnter", function()
        label:SetTextColor(primary.r, primary.g, primary.b, primary.a)
    end)

    clickArea:SetScript("OnLeave", function()
        UpdateVisuals()
    end)

    UpdateVisuals()
    frame.UpdateVisuals = UpdateVisuals

    return frame
end

------------------------------------------------------------------------
-- SLIDER (minimal line slider)
------------------------------------------------------------------------

function Widgets.CreateSlider(parent, text, dbKey, minVal, maxVal, step, onChange)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(200, 35)

    -- Label
    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.LABEL, "OUTLINE")
    label:SetShadowColor(0, 0, 0, 0.5)
    label:SetShadowOffset(1, -1)
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetText(text)

    local secondary = Config.COLORS.TEXT_SECONDARY
    label:SetTextColor(secondary.r, secondary.g, secondary.b, secondary.a)

    -- Value display
    local valueText = frame:CreateFontString(nil, "OVERLAY")
    valueText:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.LABEL, "OUTLINE")
    valueText:SetShadowColor(0, 0, 0, 0.5)
    valueText:SetShadowOffset(1, -1)
    valueText:SetPoint("TOPRIGHT", 0, 0)
    valueText:SetTextColor(secondary.r, secondary.g, secondary.b, secondary.a)

    -- Slider track (custom, OptionsSliderTemplate was removed in 10.x)
    local slider = CreateFrame("Slider", nil, frame, BackdropTemplateMixin and "BackdropTemplate" or nil)
    slider:SetSize(180, 12)
    slider:SetPoint("TOPLEFT", 0, -14)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step or 1)
    slider:SetObeyStepOnDrag(true)
    slider:SetOrientation("HORIZONTAL")
    slider:EnableMouse(true)

    -- Custom slider track visual
    local trackBg = slider:CreateTexture(nil, "BACKGROUND")
    trackBg:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    trackBg:SetHeight(2)
    trackBg:SetPoint("LEFT", 0, 0)
    trackBg:SetPoint("RIGHT", 0, 0)
    local divider = Config.COLORS.DIVIDER
    trackBg:SetVertexColor(divider.r, divider.g, divider.b, 0.3)

    -- Custom thumb
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    thumb:SetSize(8, 12)
    local primary = Config.COLORS.TEXT_PRIMARY
    thumb:SetVertexColor(primary.r, primary.g, primary.b, 0.6)
    slider:SetThumbTexture(thumb)

    local currentVal = DXD.db[dbKey] or minVal
    slider:SetValue(currentVal)
    valueText:SetText(tostring(currentVal))

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / (step or 1) + 0.5) * (step or 1)
        DXD.db[dbKey] = value
        valueText:SetText(tostring(value))
        if onChange then onChange(value) end
    end)

    return frame
end

------------------------------------------------------------------------
-- DROPDOWN (minimal text dropdown)
------------------------------------------------------------------------

function Widgets.CreateDropdown(parent, text, dbKey, options, onChange)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(200, 20)

    local secondary = Config.COLORS.TEXT_SECONDARY
    local primary = Config.COLORS.TEXT_PRIMARY

    -- Label
    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.ZONE_NAME, "OUTLINE")
    label:SetShadowColor(0, 0, 0, 0.5)
    label:SetShadowOffset(1, -1)
    label:SetPoint("LEFT", 0, 0)
    label:SetText(text .. ": ")
    label:SetTextColor(secondary.r, secondary.g, secondary.b, secondary.a)

    -- Current value
    local valueBtn = Widgets.CreateTextButton(frame, "", Config.FONT_SIZES.ZONE_NAME, function()
        -- Cycle through options
        local current = DXD.db[dbKey]
        local currentIdx = 1
        for i, opt in ipairs(options) do
            if opt.value == current then
                currentIdx = i
                break
            end
        end
        local nextIdx = (currentIdx % #options) + 1
        DXD.db[dbKey] = options[nextIdx].value
        valueBtn.label:SetText(options[nextIdx].label .. " \226\150\190")  -- ▾
        if onChange then onChange(options[nextIdx].value) end
    end)
    valueBtn:SetPoint("LEFT", label, "RIGHT", 0, 0)

    -- Set initial value
    local current = DXD.db[dbKey]
    for _, opt in ipairs(options) do
        if opt.value == current then
            valueBtn.label:SetText(opt.label .. " \226\150\190")  -- ▾
            break
        end
    end

    return frame
end
