--[[
    AceGUIWidget-SpinBox
    Custom AceGUI widget for numeric input with left/right TGA buttons
--]]

local addonName = ...
local MEDIA_PATH = "Interface\\AddOns\\" .. addonName .. "\\Media\\"

local AceGUI = LibStub("AceGUI-3.0")

local widgetType = "SpinBox"
local widgetVersion = 1

local function OnButtonClick(self, delta)
    local editbox = self:GetParent().editbox
    local value = tonumber(editbox:GetText()) or 0
    value = value + delta
    editbox:SetText(tostring(value))
    if editbox.OnValueChanged then
        editbox:OnValueChanged(value)
    end
end

local function OnButtonDown(self, delta)
    self._repeatDelta = delta
    self._repeatTimer = 0
    self:SetScript("OnUpdate", function(btn, elapsed)
        btn._repeatTimer = btn._repeatTimer + elapsed
        while btn._repeatTimer >= 0.05 do
            btn._repeatTimer = btn._repeatTimer - 0.05
            OnButtonClick(btn, btn._repeatDelta)
        end
    end)
end

local function OnButtonUp(self)
    self:SetScript("OnUpdate", nil)
end

local function Constructor()
    local frame = CreateFrame("Frame")
    frame:SetSize(100, 20)  -- width will expand in layout
    local widget = {}
    widget.frame = frame
    widget.type = widgetType

    -- EditBox
    local editbox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    editbox:SetAutoFocus(false)
    editbox:SetSize(60, 20)
    editbox:SetPoint("CENTER", frame, 0, 0)
    editbox:SetJustifyH("CENTER")
    widget.editbox = editbox

    -- Left button
    local btnLeft = CreateFrame("Button", nil, frame)
    btnLeft:SetSize(20, 20)
    btnLeft:SetPoint("RIGHT", editbox, "LEFT", -2, 0)
    btnLeft.texture = btnLeft:CreateTexture(nil, "BACKGROUND")
    btnLeft.texture:SetAllPoints()
    btnLeft.texture:SetTexture(MEDIA_PATH.."spinboxleft.tga")
    btnLeft:SetScript("OnClick", function() OnButtonClick(btnLeft, -1) end)
    btnLeft:SetScript("OnMouseDown", function() OnButtonDown(btnLeft, -1) end)
    btnLeft:SetScript("OnMouseUp", function() OnButtonUp(btnLeft) end)
    btnLeft:SetScript("OnMouseLeave", function() OnButtonUp(btnLeft) end)

    -- Right button
    local btnRight = CreateFrame("Button", nil, frame)
    btnRight:SetSize(20, 20)
    btnRight:SetPoint("LEFT", editbox, "RIGHT", 2, 0)
    btnRight.texture = btnRight:CreateTexture(nil, "BACKGROUND")
    btnRight.texture:SetAllPoints()
    btnRight.texture:SetTexture(MEDIA_PATH.."spinboxright.tga")
    btnRight:SetScript("OnClick", function() OnButtonClick(btnRight, 1) end)
    btnRight:SetScript("OnMouseDown", function() OnButtonDown(btnRight, 1) end)
    btnRight:SetScript("OnMouseUp", function() OnButtonUp(btnRight) end)
    btnRight:SetScript("OnMouseLeave", function() OnButtonUp(btnRight) end)

    -- Widget methods
    function widget:SetValue(val)
        editbox:SetText(tostring(val))
    end

    function widget:GetValue()
        return tonumber(editbox:GetText()) or 0
    end

    function widget:SetCallback(event, func)
        if event == "OnValueChanged" then
            editbox.OnValueChanged = func
        else
            AceGUI:RegisterCallback(widget, event, func)
        end
    end

    function widget:SetDisabled(disabled)
        editbox:SetEnabled(not disabled)
        btnLeft:EnableMouse(not disabled)
        btnRight:EnableMouse(not disabled)
    end

    function widget:SetWidth(width)
        frame:SetWidth(width)
        local w = math.max(width - 44, 20)
        editbox:SetWidth(w)
    end

    function widget:SetHeight(height)
        frame:SetHeight(height)
        editbox:SetHeight(height)
        btnLeft:SetHeight(height)
        btnRight:SetHeight(height)
    end

    function widget:SetLabel(text)
        -- optional: you can add a label frame above or left if needed
        -- for AceConfig, labels are handled automatically
    end

    function widget:SetTooltip(text)
        frame:SetScript("OnEnter", function()
            if text then
                GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
                GameTooltip:SetText(text, 1,1,1)
                GameTooltip:Show()
            end
        end)
        frame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    -- EditBox events
    editbox:SetScript("OnEnterPressed", function()
        if editbox.OnValueChanged then
            local val = tonumber(editbox:GetText()) or 0
            editbox:OnValueChanged(val)
        end
    end)

    -- OnAcquire / OnRelease
    function widget:OnAcquire()
        self:SetDisabled(false)
        self:SetWidth(100)
        self:SetHeight(20)
    end

    function widget:OnRelease()
        editbox:SetText("")
        editbox.OnValueChanged = nil
    end

    AceGUI:RegisterAsWidget(widget)
    return widget
end

AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion)
