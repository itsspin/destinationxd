------------------------------------------------------------------------
-- DestinationXD - SettingsPanel.lua
-- Options panel: Interface -> AddOns -> DestinationXD
-- Design: frosted glass, barely there, radical minimalism
------------------------------------------------------------------------
local ADDON_NAME, DXD = ...

local SettingsPanel = {}
DXD:RegisterModule("SettingsPanel", SettingsPanel)

local Config = DXD.Config
local Widgets = DXD.Widgets

-- Main frame
local settingsFrame
local isVisible = false

------------------------------------------------------------------------
-- SETTING ELEMENT CREATORS
------------------------------------------------------------------------

local function CreateSectionHeader(parent, text, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY")
    header:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.LABEL, "OUTLINE")
    header:SetShadowColor(0, 0, 0, 0.5)
    header:SetShadowOffset(1, -1)
    header:SetPoint("TOPLEFT", 0, yOffset)
    header:SetText(text)

    local tertiary = Config.COLORS.TEXT_TERTIARY
    header:SetTextColor(tertiary.r, tertiary.g, tertiary.b, tertiary.a)

    return yOffset - 20
end

local function CreateCheckboxSetting(parent, text, dbKey, yOffset)
    local checkbox = Widgets.CreateCheckbox(parent, text, dbKey)
    checkbox:SetPoint("TOPLEFT", 4, yOffset)
    return yOffset - 24
end

local function CreateSliderSetting(parent, text, dbKey, minVal, maxVal, step, yOffset)
    local slider = Widgets.CreateSlider(parent, text, dbKey, minVal, maxVal, step)
    slider:SetPoint("TOPLEFT", 4, yOffset)
    return yOffset - 40
end

local function CreateDropdownSetting(parent, text, dbKey, options, yOffset)
    local dropdown = Widgets.CreateDropdown(parent, text, dbKey, options)
    dropdown:SetPoint("TOPLEFT", 4, yOffset)
    return yOffset - 24
end

------------------------------------------------------------------------
-- FRAME CREATION
------------------------------------------------------------------------

local function CreateSettingsPanel()
    -- Main container
    settingsFrame = CreateFrame("Frame", "DXDSettingsFrame", UIParent, "BackdropTemplate")
    settingsFrame:SetSize(320, 480)
    settingsFrame:SetPoint("CENTER")
    settingsFrame:SetFrameStrata("DIALOG")
    settingsFrame:SetFrameLevel(100)

    -- Frosted glass background
    settingsFrame:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    local bg = Config.COLORS.PANEL_BG
    settingsFrame:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
    settingsFrame:SetBackdropBorderColor(1, 1, 1, 0.08)

    -- Make movable
    settingsFrame:SetMovable(true)
    settingsFrame:EnableMouse(true)
    settingsFrame:RegisterForDrag("LeftButton")
    settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
    settingsFrame:SetScript("OnDragStop", settingsFrame.StopMovingOrSizing)
    settingsFrame:SetClampedToScreen(true)

    -- Close on Escape
    table.insert(UISpecialFrames, "DXDSettingsFrame")

    -- Title
    local title = settingsFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.HEADER, "OUTLINE")
    title:SetShadowColor(0, 0, 0, 0.5)
    title:SetShadowOffset(1, -1)
    title:SetPoint("TOPLEFT", 16, -12)
    local secondary = Config.COLORS.TEXT_SECONDARY
    title:SetTextColor(secondary.r, secondary.g, secondary.b, secondary.a)
    title:SetText("DESTINATION")

    -- Version
    local version = settingsFrame:CreateFontString(nil, "OVERLAY")
    version:SetFont("Fonts\\FRIZQT__.TTF", Config.FONT_SIZES.LABEL, "OUTLINE")
    version:SetShadowColor(0, 0, 0, 0.5)
    version:SetShadowOffset(1, -1)
    version:SetPoint("LEFT", title, "RIGHT", 8, 0)
    local tertiary = Config.COLORS.TEXT_TERTIARY
    version:SetTextColor(tertiary.r, tertiary.g, tertiary.b, tertiary.a)
    version:SetText("v" .. DXD.version)

    -- Close button
    local closeBtn = Widgets.CreateCloseButton(settingsFrame)
    closeBtn:SetPoint("TOPRIGHT", -8, -8)

    -- Scroll area for settings
    local scrollContainer = Widgets.CreateScrollFrame(settingsFrame, 288, 430)
    scrollContainer:SetPoint("TOPLEFT", 16, -40)
    local content = scrollContainer.content

    -- Build settings sections
    local yOffset = 0

    -- === GENERAL ===
    yOffset = CreateSectionHeader(content, "GENERAL", yOffset)
    yOffset = CreateCheckboxSetting(content, "Enable DestinationXD", "enabled", yOffset)
    yOffset = CreateCheckboxSetting(content, "Play sounds on arrival", "playSounds", yOffset)
    yOffset = CreateCheckboxSetting(content, "Auto-clear on arrival", "autoClearOnArrival", yOffset)
    yOffset = CreateSliderSetting(content, "Arrival distance", "arrivalDistance", 2, 15, 1, yOffset)

    -- === TRAVEL PLANNER ===
    yOffset = yOffset - 12
    yOffset = CreateSectionHeader(content, "TRAVEL PLANNER", yOffset)
    yOffset = CreateCheckboxSetting(content, "Consider hearthstone CD", "considerHearthstoneCooldown", yOffset)

    -- === RADIAL MENU ===
    yOffset = yOffset - 12
    yOffset = CreateSectionHeader(content, "QUICK ACCESS", yOffset)
    yOffset = CreateCheckboxSetting(content, "Enable radial menu", "radialMenuEnabled", yOffset)
    yOffset = CreateDropdownSetting(content, "Hotkey", "radialMenuKey",
        { {label = "` (Tilde)", value = "`"}, {label = "TAB", value = "TAB"}, {label = "ALT", value = "LALT"}, {label = "CTRL", value = "LCTRL"} }, yOffset)

    -- === INTEGRATIONS ===
    yOffset = yOffset - 12
    yOffset = CreateSectionHeader(content, "INTEGRATIONS", yOffset)
    yOffset = CreateCheckboxSetting(content, "TomTom compatibility", "tomtomCompat", yOffset)
    yOffset = CreateCheckboxSetting(content, "HandyNotes compatibility", "handyNotesCompat", yOffset)

    -- Set content height
    content:SetHeight(math.abs(yOffset) + 20)

    settingsFrame:Hide()
end

------------------------------------------------------------------------
-- PUBLIC API
------------------------------------------------------------------------

function SettingsPanel:Toggle()
    if not settingsFrame then return end
    if settingsFrame:IsShown() then
        settingsFrame:Hide()
    else
        settingsFrame:Show()
    end
end

function SettingsPanel:Show()
    if settingsFrame then settingsFrame:Show() end
end

function SettingsPanel:Hide()
    if settingsFrame then settingsFrame:Hide() end
end

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

function SettingsPanel:Initialize()
    CreateSettingsPanel()

    -- Register with Blizzard's addon settings
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(settingsFrame, "DestinationXD")
        Settings.RegisterAddOnCategory(category)
    end

    DXD:Debug("SettingsPanel initialized")
end
