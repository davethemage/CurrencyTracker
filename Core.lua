local addonName, addon = ...
addon.shortName = "CT"
addon.longName = "Currency Tracker"
addon.version = "1.0.6"
CurrencyTracker = LibStub("AceAddon-3.0"):NewAddon(
    addonName,
    "AceConsole-3.0",
    "AceEvent-3.0"
)

local LSM = LibStub("LibSharedMedia-3.0")

-- -----------------------
-- Defaults
-- -----------------------
local defaults = {
    profile = {
        display = {
            grow = "RIGHT",
            screenAnchor = "CENTER",
            trackerAnchor = "CENTER",
            padding = 2,
            x = 0,
            y = 0,
            iconSize = 16,
            fontSize = 12,
            font = "Friz Quadrata TT",
            hideEmpty = false,
            unlocked = false,
            zoom = false,
        },
        currencies = {
            -- [CURRENCY_ID] = { 
            --     ["order"] = 1,
            --     ["color"] = {
            --         ["r"] = 0,
            --         ["g"] = 0,
            --         ["b"] = 0,
            --     },
            -- },
        },
    }
}
local default_currencies  = {
    -- Midnight S1
    [3383] = { -- Adventurer
        ["order"] = 1,
        ["color"] = {
            ["r"] = 1,
            ["g"] = 1,
            ["b"] = 1,
        },
    },
    [3341] = { -- Veteran
        ["order"] = 2,
        ["color"] = {
            ["r"] = 0.1176470667123795,
            ["g"] = 1,
            ["b"] = 0,
        },
    },
    [3343] = {  -- Champion
        ["order"] = 3,
        ["color"] = {
            ["r"] = 0,
            ["g"] = 0.4392157196998596,
            ["b"] = 0.8666667342185974,
        },
    },
    [3345] = { -- Heroic
        ["order"] = 4,
        ["color"] = {
            ["r"] = 0.6392157077789307,
            ["g"] = 0.207843154668808,
            ["b"] = 0.9333333969116211,
        },
    },
    [3347] = { -- Mythic
        ["order"] = 5,
        ["color"] = {
            ["r"] = 1,
            ["g"] = 0.5,
            ["b"] = 0,
        },
    },
    -- TWW S3
    -- [3008] = { -- Valorstones
    --     ["order"] = 1,
    --     ["color"] = {
    --         ["r"] = 0,
    --         ["g"] = 0.8666667342185974,
    --         ["b"] = 0.8666667342185974,
    --     },
    -- },
    -- [3284] = { -- Weathered
    --     ["order"] = 2,
    --     ["color"] = {
    --         ["r"] = 1,
    --         ["g"] = 1,
    --         ["b"] = 1,
    --     },
    -- },
    -- [3286] = { -- Carved
    --     ["order"] = 3,
    --     ["color"] = {
    --         ["r"] = 0.1176470667123795,
    --         ["g"] = 1,
    --         ["b"] = 0,
    --     },
    -- },
    -- [3288] = {  -- Runed
    --     ["order"] = 4,
    --     ["color"] = {
    --         ["r"] = 0,
    --         ["g"] = 0.4392157196998596,
    --         ["b"] = 0.8666667342185974,
    --     },
    -- },
    -- [3290] = { -- Gilded
    --     ["order"] = 5,
    --     ["color"] = {
    --         ["r"] = 0.6392157077789307,
    --         ["g"] = 0.207843154668808,
    --         ["b"] = 0.9333333969116211,
    --     },
    -- },
}
-- -----------------------
-- Helpers
-- -----------------------
function CurrencyTracker:IsSafe()
    return not InCombatLockdown()
        and not UnitIsDeadOrGhost("player")
end

-- -----------------------
-- Lifecycle
-- -----------------------
function CurrencyTracker:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("CurrencyTrackerDB", defaults, true)
    self:SetupOptions()
    self:RegisterChatCommand(addon.shortName:lower(), "OpenOptions")

    -- Register profile change callbacks
    self.db.RegisterCallback(self, "OnProfileChanged", "RequestUpdate")
    self.db.RegisterCallback(self, "OnProfileCopied", "RequestUpdate")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileReset")
    self.db.RegisterCallback(self, "OnProfileDeleted", "RequestUpdate")

    CurrencyTracker_Mover:Initialize()
    CurrencyTracker_Display:Initialize()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00["..addon.shortName.."]|r ".. addon.longName .." v".. addon.version .. " - |cff00ff00/".. addon.shortName:lower() .. "|r")
end

function CurrencyTracker:OnEnable()
    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE", "RequestUpdate")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "RequestUpdate")
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "RequestUpdate")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "RequestUpdate")
    self:AddDefaultCurrenciesIfNeeded()
end

function CurrencyTracker:AddDefaultCurrenciesIfNeeded()
    -- Check each currency in the saved data
    local function count_table(table)
        local count = 0
        for _ in pairs(table) do
            count = count + 1
        end
        return count
    end
    if  self.db.profile.currencies == nil or count_table(self.db.profile.currencies) == 0 then
        self.db.profile.currencies = CopyTable(default_currencies)
    end
end

function CurrencyTracker:OnProfileReset()
    self:AddDefaultCurrenciesIfNeeded()
    self:RebuildTrackedCurrencies()
    self:RequestUpdate()
end
function CurrencyTracker:RequestUpdate()
    --if not self:IsSafe() then return end
    CurrencyTracker_Display:Update()
end

function CurrencyTracker:OpenOptions()
    LibStub("AceConfigDialog-3.0"):Open(addonName)
end