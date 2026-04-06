local CT = CurrencyTracker
local LSM = LibStub("LibSharedMedia-3.0")

CurrencyTracker_Display = {}

local rows = {}

function CurrencyTracker_Display:Initialize()
    self.parent = CurrencyTracker_Mover.frame
    self:ApplyVisibility()
end

local function CreateRow(index)
    local f = CreateFrame("Frame", nil, CurrencyTracker_Mover.frame)

    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.text = f:CreateFontString(nil, "OVERLAY")

    f.text:SetJustifyH("LEFT")

    rows[index] = f
    return f
end

-- Return currencies sorted by 'order' from DB
local function GetOrderedCurrencies()
    local list = {}
    for id, data in pairs(CT.db.profile.currencies) do
        table.insert(list, { id = id, order = data.order or 0 })
    end
    table.sort(list, function(a, b) return a.order < b.order end)
    return list
end


-- -----------------------
-- Combat visibility
-- -----------------------
function CurrencyTracker_Display:ApplyVisibility()
    --if already in combat, do not update visibility
    if InCombatLockdown() or UnitIsDeadOrGhost("player") then return end
    local frame = self.parent
    UnregisterStateDriver(frame, "visibility")

    if CT.db.profile.display.hideInCombat then
        RegisterStateDriver(frame, "visibility", "[combat][dead] hide; show")
    else
        RegisterStateDriver(frame, "visibility", "show")
    end
end

function CurrencyTracker_Display:Update()
    self:ApplyVisibility()
    if not CT:IsSafe() then return end

    local d = CT.db.profile.display

    local font = LSM:Fetch("font", d.font)
    local index = 1
    local totalWidth = 0
    local totalHeight = 0
    local visibleCount = 0
    local lastRow = nil

    local orderedCurrencies = {}
    for _, entry in ipairs(GetOrderedCurrencies()) do
        local currencyID = entry.id
        local data = CT.db.profile.currencies[currencyID]
        local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
        if info and not (d.hideEmpty and info.quantity == 0) then
            table.insert(orderedCurrencies, {id = currencyID, data = data, info = info})
        end
    end

    for _, entry in ipairs(orderedCurrencies) do
        local currencyID = entry.id
        local data = entry.data
        local info = entry.info

        local row = rows[index] or CreateRow(index)

        -- Icon
        row.icon:SetTexture(info.iconFileID)
        if d.zoom then
            local zoom_level = 0.1
            row.icon:SetTexCoord(zoom_level, 1 - zoom_level, zoom_level, 1 - zoom_level)
        else
            row.icon:SetTexCoord(0, 1, 0, 1)
        end
        row.icon:SetSize(d.iconSize, d.iconSize)
        row.icon:ClearAllPoints()
        row.icon:SetPoint("LEFT", row, "LEFT")
        row.icon:SetScript("OnEnter", function()
            GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
            GameTooltip:SetCurrencyByID(currencyID)
        end)
        row.icon:SetScript("OnLeave", GameTooltip_Hide)

        -- Text color
        local color = data.color or { r = 1, g = 1, b = 1 }
        local r, g, b = color.r, color.g, color.b
        if info.quantity == 0 or info.totalEarned == info.maxQuantity then
            r, g, b = 1, 0, 0
        end

        row.text:SetFont(font, d.fontSize, "OUTLINE")
        row.text:SetTextColor(r, g, b)
        row.text:SetText(info.quantity)
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)

        -- Row sizing
        local rowWidth = d.iconSize + row.text:GetStringWidth() + 4
        local rowHeight = math.max(d.iconSize, d.fontSize)
        row:SetSize(rowWidth, rowHeight)

        -- Positioning
        row:ClearAllPoints()
        if lastRow then
            if d.grow == "RIGHT" then
                row:SetPoint("LEFT", lastRow, "RIGHT", d.padding, 0)
            elseif d.grow == "LEFT" then
                row:SetPoint("RIGHT", lastRow, "LEFT", -d.padding, 0)
            elseif d.grow == "UP" then
                row:SetPoint("BOTTOM", lastRow, "TOP", 0, d.padding)
            else
                row:SetPoint("TOP", lastRow, "BOTTOM", 0, -d.padding)
            end
        else
            if d.grow == "RIGHT" then
                row:SetPoint("LEFT", CurrencyTracker_Mover.frame, "LEFT")
            elseif d.grow == "LEFT" then
                row:SetPoint("RIGHT", CurrencyTracker_Mover.frame, "RIGHT")
            elseif d.grow == "UP" then
                row:SetPoint("BOTTOM", CurrencyTracker_Mover.frame, "BOTTOM")
            else
                row:SetPoint("TOP", CurrencyTracker_Mover.frame, "TOP")
            end
        end

        row:Show()
        lastRow = row
        visibleCount = visibleCount + 1

        -- Dynamic sizing
        if d.grow == "LEFT" or d.grow == "RIGHT" then
            totalWidth = totalWidth + rowWidth
            totalHeight = math.max(totalHeight, rowHeight)
            if visibleCount > 1 then totalWidth = totalWidth + d.padding end
        else
            totalWidth = math.max(totalWidth, rowWidth)
            totalHeight = totalHeight + rowHeight
            if visibleCount > 1 then totalHeight = totalHeight + d.padding end
        end

        index = index + 1
    end

    -- Hide leftover rows
    for i = index, #rows do
        rows[i]:Hide()
    end

    -- Resize mover
    if CurrencyTracker_Mover.SetSizeForContent then
        CurrencyTracker_Mover:SetSizeForContent(totalWidth, totalHeight)
    end
    -- Update location
    CurrencyTracker_Mover:Reset()
end
