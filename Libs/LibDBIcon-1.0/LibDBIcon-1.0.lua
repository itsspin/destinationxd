-- LibDBIcon-1.0 - Minimap icon library
-- Standard library for creating minimap buttons

local MAJOR, MINOR = "LibDBIcon-1.0", 52
local LibDBIcon, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not LibDBIcon then return end

local LDB = LibStub("LibDataBroker-1.1")

LibDBIcon.objects = LibDBIcon.objects or {}
LibDBIcon.callbackRegistered = LibDBIcon.callbackRegistered or false
LibDBIcon.callbacks = LibDBIcon.callbacks or LibStub("CallbackHandler-1.0"):New(LibDBIcon)
LibDBIcon.notCreated = LibDBIcon.notCreated or {}

local objects = LibDBIcon.objects

local function CreateMinimapButton(name, obj, db)
    local button = CreateFrame("Button", "LibDBIcon10_" .. name, Minimap)
    button:SetFrameStrata("MEDIUM")
    button:SetSize(31, 31)
    button:SetFrameLevel(8)
    button:RegisterForClicks("AnyUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture(136477) -- Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight

    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture(136430) -- Interface\\Minimap\\MiniMap-TrackingBorder
    overlay:SetPoint("TOPLEFT")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetTexture(136467) -- Interface\\Minimap\\UI-Minimap-Background
    background:SetPoint("TOPLEFT", 7, -5)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetPoint("TOPLEFT", 7, -6)

    if obj.icon then
        icon:SetTexture(obj.icon)
    end

    button.icon = icon
    button.dataObject = obj

    -- Position on minimap
    local minimapAngle = db and db.minimapPos or 225
    local radius = 80
    local radian = math.rad(minimapAngle)
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(radian) * radius, math.sin(radian) * radius)

    -- Click handling
    button:SetScript("OnClick", function(self, btn)
        if obj.OnClick then
            obj.OnClick(self, btn)
        end
    end)

    button:SetScript("OnEnter", function(self)
        if obj.OnTooltipShow then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            obj.OnTooltipShow(GameTooltip)
            GameTooltip:Show()
        end
    end)

    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Drag for repositioning
    button:SetScript("OnDragStart", function(self)
        self:StartMoving()
        self.isMoving = true
    end)

    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self.isMoving = false
        -- Calculate angle from minimap center
        local mx, my = Minimap:GetCenter()
        local bx, by = self:GetCenter()
        local angle = math.deg(math.atan2(by - my, bx - mx))
        if db then db.minimapPos = angle end
    end)

    button:SetMovable(true)

    if db and db.hide then
        button:Hide()
    end

    objects[name] = button
    return button
end

function LibDBIcon:Register(name, obj, db)
    if objects[name] then return end
    if not db then db = {} end
    CreateMinimapButton(name, obj, db)
end

function LibDBIcon:Unregister(name)
    if objects[name] then
        objects[name]:Hide()
        objects[name] = nil
    end
end

function LibDBIcon:Show(name)
    if objects[name] then
        objects[name]:Show()
    end
end

function LibDBIcon:Hide(name)
    if objects[name] then
        objects[name]:Hide()
    end
end

function LibDBIcon:IsRegistered(name)
    return objects[name] ~= nil
end

function LibDBIcon:GetMinimapButton(name)
    return objects[name]
end
