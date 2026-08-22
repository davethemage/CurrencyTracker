local CT = CurrencyTracker
local LSM = LibStub("LibSharedMedia-3.0")

CurrencyTracker_Mover = CurrencyTracker_Mover or {}

function CurrencyTracker_Mover:SavePosition()
    if not self.frame then return end

    local d = CT.db.profile.display
    local centerX, centerY = self.frame:GetCenter()
    if not centerX or not centerY then return end

    local frameWidth, frameHeight = self.frame:GetSize()
    local screenWidth, screenHeight = UIParent:GetSize()

    local screenAnchorX = 0
    if d.screenAnchor:find("RIGHT") then
        screenAnchorX = screenWidth
    elseif not d.screenAnchor:find("LEFT") then
        screenAnchorX = screenWidth / 2
    end

    local trackerOffsetX = 0
    if d.trackerAnchor:find("RIGHT") then
        trackerOffsetX = frameWidth / 2
    elseif not d.trackerAnchor:find("LEFT") then
        trackerOffsetX = 0
    else
        trackerOffsetX = -frameWidth / 2
    end

    local screenAnchorY = 0
    if d.screenAnchor:find("TOP") then
        screenAnchorY = screenHeight
    elseif not d.screenAnchor:find("BOTTOM") then
        screenAnchorY = screenHeight / 2
    end

    local trackerOffsetY = 0
    if d.trackerAnchor:find("TOP") then
        trackerOffsetY = frameHeight / 2
    elseif d.trackerAnchor:find("BOTTOM") then
        trackerOffsetY = -frameHeight / 2
    end

    d.x = centerX - screenAnchorX + trackerOffsetX
    d.y = centerY - screenAnchorY + trackerOffsetY
end

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
        self:SavePosition()
    end)

    -- Background texture (modern replacement for SetBackdrop)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    bg:SetColorTexture(0, 1, 1, 0.3)
    bg:Hide()

    f.bg = bg
    self.frame = f

    self:Reset()
    self:SetUnlocked(CT.db.profile.display.unlocked)
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