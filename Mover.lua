local CT = CurrencyTracker
local LSM = LibStub("LibSharedMedia-3.0")

CurrencyTracker_Mover = CurrencyTracker_Mover or {}

function CurrencyTracker_Mover:Initialize()
    local f = CreateFrame("Frame", "CurrencyTrackerMover", UIParent)
    f:SetSize(1, 1)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(false)

    f:RegisterForDrag("LeftButton")

    f:SetScript("OnDragStart", function()
        if CT.db.profile.display.unlocked then
            f:StartMoving()
        end
    end)

    f:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local _, _, _, x, y = f:GetPoint()
        CT.db.profile.display.x = x
        CT.db.profile.display.y = y
    end)

    -- Background texture (modern replacement for SetBackdrop)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    bg:SetColorTexture(0, 1, 1, 0.3)
    bg:Hide()

    f.bg = bg
    self.frame = f

    self:Reset()
end

-- -----------------------
-- Fade helpers
-- -----------------------
function CurrencyTracker_Mover:FadeIn()
    self.frame.bg:StopAnimating()
    self.frame.bg:SetAlpha(0.3)
    self.frame.bg:Show()
end

function CurrencyTracker_Mover:FadeOut()
    self.frame.bg:StopAnimating()
    self.frame.bg:Hide()
end

-- -----------------------
-- Unlock handling
-- -----------------------
function CurrencyTracker_Mover:SetUnlocked(unlocked)
    if InCombatLockdown() then return end

    self.frame:EnableMouse(unlocked)

    if unlocked then
        self:FadeIn()
    else
        self:FadeOut()
    end
end

-- -----------------------
-- Dynamic sizing
-- -----------------------
function CurrencyTracker_Mover:SetSizeForContent(width, height)
    if InCombatLockdown() then return end

    self.frame:SetSize(
        math.max(width, 1),
        math.max(height, 1)
    )
end

-- -----------------------
-- Position reset
-- -----------------------
function CurrencyTracker_Mover:Reset()
    if InCombatLockdown() then return end

    local d = CT.db.profile.display
    self.frame:ClearAllPoints()
    self.frame:SetPoint(
        d.trackerAnchor,
        UIParent,
        d.screenAnchor,
        d.x,
        d.y
    )
end