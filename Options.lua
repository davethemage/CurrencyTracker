local addonName = ...
local CT = CurrencyTracker
local LSM = LibStub("LibSharedMedia-3.0")

local options

-- -------------------------------------------------
-- Helpers
-- -------------------------------------------------
local function GetOrderedCurrencies()
    local list = {}
    for id, data in pairs(CT.db.profile.currencies) do
        table.insert(list, { id = id, order = data.order or 0 })
    end
    table.sort(list, function(a, b)
        return a.order < b.order
    end)
    return list
end

local function GetNextOrder()
    local maxOrder = 0
    for _, data in pairs(CT.db.profile.currencies) do
        maxOrder = math.max(maxOrder, data.order or 0)
    end
    return maxOrder + 1
end

local function SwapCurrencies(id1, id2)
    local t1, t2 = CT.db.profile.currencies[id1], CT.db.profile.currencies[id2]
    t1.order, t2.order = t2.order, t1.order
end

-- -------------------------------------------------
-- Add Currency dropdown
-- -------------------------------------------------
local function GetAvailableCurrencies()
    local values = {}
    local size = C_CurrencyInfo.GetCurrencyListSize()
    if not size then return values end

    for i = 1, size do
        local info = C_CurrencyInfo.GetCurrencyListInfo(i)
        if info and info.currencyID and not CT.db.profile.currencies[info.currencyID] and not info.isHeader then
            values[info.currencyID] = info.name
        end
    end

    return values
end

-- -------------------------------------------------
-- Build tracked currencies
-- -------------------------------------------------
local function RebuildTrackedCurrencies()
    if not options then return end
    local trackedGroup = options.args.currencies.args.tracked.args
    wipe(trackedGroup)

    local ordered = GetOrderedCurrencies()
    local index = 0

    for _, entry in ipairs(ordered) do
        local currencyID = entry.id
        local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
        if info then
            index = index + 1

            trackedGroup["currency_" .. currencyID] = {
                type = "group",
                name = info.name,
                inline = true,
                order = index,
                args = {
                    moveUp = {
                        type = "execute",
                        name = "",
                        order = 1,
                        width = 0.1,
                        func = function()
                            local ordered = GetOrderedCurrencies()
                            for i, row in ipairs(ordered) do
                                if row.id == currencyID and i > 1 then
                                    SwapCurrencies(currencyID, ordered[i-1].id)
                                    RebuildTrackedCurrencies()
                                    CT:RequestUpdate()
                                    break
                                end
                            end
                        end,
                        image = "Interface\\Addons\\CurrencyTracker\\Media\\ArrowUp.tga",
                        imageWidth = 16,
                        imageHeight = 16,
                    },
                    moveDown = {
                        type = "execute",
                        name = "",
                        order = 2,
                        width = 0.1,
                        func = function()
                            local ordered = GetOrderedCurrencies()
                            for i, row in ipairs(ordered) do
                                if row.id == currencyID and i < #ordered then
                                    SwapCurrencies(currencyID, ordered[i+1].id)
                                    RebuildTrackedCurrencies()
                                    CT:RequestUpdate()
                                    break
                                end
                            end
                        end,
                        image = "Interface\\Addons\\CurrencyTracker\\Media\\ArrowDown.tga",
                        imageWidth = 16,
                        imageHeight = 16,
                    },
                    color = {
                        type = "color",
                        name = "Text Color",
                        order = 4,
                        width = 1.7, -- takes most of the middle
                        get = function()
                            local c = CT.db.profile.currencies[currencyID].color
                            return c.r, c.g, c.b
                        end,
                        set = function(_, r, g, b)
                            local c = CT.db.profile.currencies[currencyID].color
                            c.r, c.g, c.b = r, g, b
                            CT:RequestUpdate()
                        end,
                    },
                    delete = {
                        type = "execute",
                        name = "",
                        order = 3,
                        width = 0.1, -- right side
                        func = function()
                            CT.db.profile.currencies[currencyID] = nil
                            RebuildTrackedCurrencies()
                            CT:RequestUpdate()
                        end,
                        image = "Interface\\Addons\\CurrencyTracker\\Media\\delete.tga",
                        imageWidth = 16,
                        imageHeight = 16,
                    },
                },
            }
        end
    end
end

-- -------------------------------------------------
-- Setup Options
-- -------------------------------------------------
function CT:SetupOptions()
    options = {
        type = "group",
        name = "CurrencyTracker",
        args = {
            -- =========================
            -- Display Tab
            -- =========================
            display = {
                type = "group",
                name = "Display",
                order = 1,
                args = {

                    -- -------------------------
                    -- Look & Feel
                    -- -------------------------
                    lookFeelHeader = {
                        type = "header",
                        name = "Look & Feel",
                        order = 1,
                    },
                    font = {
                        type = "select",
                        dialogControl = "LSM30_Font",
                        name = "Font",
                        width = 1,
                        values = LSM:HashTable("font"),
                        get = function() return CT.db.profile.display.font end,
                        set = function(_, v) CT.db.profile.display.font = v; CT:RequestUpdate() end,
                        order = 4,
                    },
                    fontSize = {
                        type = "range",
                        name = "Font Size",
                        width = 0.8,
                        min = 8, max = 32, step = 1,
                        get = function() return CT.db.profile.display.fontSize end,
                        set = function(_, v) CT.db.profile.display.fontSize = v; CT:RequestUpdate() end,
                        order = 5,
                    },
                    iconSize = {
                        type = "range",
                        name = "Icon Size",
                        width = 0.8,
                        min = 8, max = 64, step = 1,
                        get = function() return CT.db.profile.display.iconSize end,
                        set = function(_, v) CT.db.profile.display.iconSize = v; CT:RequestUpdate() end,
                        order = 6,
                    },
                    grow = {
                        type = "select",
                        name = "Grow Direction",
                        width = 1,
                        values = { UP="Up", DOWN="Down", LEFT="Left", RIGHT="Right" },
                        get = function() return CT.db.profile.display.grow end,
                        set = function(_, v) CT.db.profile.display.grow = v; CT:RequestUpdate() end,
                        order = 2,
                    },
                    padding = {
                        type = "range",
                        name = "Padding",
                        width = 0.8,
                        min = 0, max = 20, step = 1,
                        get = function() return CT.db.profile.display.padding end,
                        set = function(_, v) CT.db.profile.display.padding = v; CT:RequestUpdate() end,
                        order = 7,
                    },
                    spacer1= {
                        type = "description",
                        name = " ",
                        width = 0.1,
                        order = 3,
                    },

                    -- -------------------------
                    -- Position
                    -- -------------------------
                    positionHeader = {
                        type = "header",
                        name = "Position",
                        order = 10,
                    },
                    -- X Position with < and > buttons
                    xPos_dec = {
                        type = "execute",
                        name = "",  -- hide text
                        image = "Interface\\Addons\\CurrencyTracker\\Media\\spinboxleft.tga",
                        imageWidth = 10,
                        imageHeight = 10,
                        width = 0.05,
                        order = 11,
                        func = function()
                            CT.db.profile.display.x = (CT.db.profile.display.x or 0) - 1
                            CurrencyTracker_Mover:Reset()
                        end,
                    },
                    xPos = {
                        type = "input",
                        name = "X Position",
                        width = 0.5,
                        order = 12,
                        get = function() return tostring(CT.db.profile.display.x) end,
                        set = function(_, v)
                            CT.db.profile.display.x = tonumber(v) or 0
                            CurrencyTracker_Mover:Reset()
                        end,
                    },
                    xPos_inc = {
                        type = "execute",
                        name = "",  -- hide text
                        image = "Interface\\Addons\\CurrencyTracker\\Media\\spinboxright.tga",
                        imageWidth = 10,
                        imageHeight = 10,
                        width = 0.05,
                        order = 13,
                        func = function()
                            CT.db.profile.display.x = (CT.db.profile.display.x or 0) + 1
                            CurrencyTracker_Mover:Reset()
                        end,
                    },
                    spacer2= {
                        type = "description",
                        name = " ",
                        width = 0.1,
                        order = 14,
                    },
                    -- Y Position with < and > buttons
                    yPos_dec = {
                        type = "execute",
                        name = "",  -- hide text
                        image = "Interface\\Addons\\CurrencyTracker\\Media\\spinboxleft.tga",
                        imageWidth = 10,
                        imageHeight = 10,
                        width = 0.05,
                        order = 15,
                        func = function()
                            CT.db.profile.display.y = (CT.db.profile.display.y or 0) - 1
                            CurrencyTracker_Mover:Reset()
                        end,
                    },
                    yPos = {
                        type = "input",
                        name = "Y Position",
                        width = 0.5,
                        order = 16,
                        get = function() return tostring(CT.db.profile.display.y) end,
                        set = function(_, v)
                            CT.db.profile.display.y = tonumber(v) or 0
                            CurrencyTracker_Mover:Reset()
                        end,
                    },
                    yPos_inc = {
                        type = "execute",
                        name = "",  -- hide text
                        image = "Interface\\Addons\\CurrencyTracker\\Media\\spinboxright.tga",
                        imageWidth = 10,
                        imageHeight = 10,
                        width = 0.05,
                        order = 17,
                        func = function()
                            CT.db.profile.display.y = (CT.db.profile.display.y or 0) + 1
                            CurrencyTracker_Mover:Reset()
                        end,
                    },
                    spacer3= {
                        type = "description",
                        name = " ",
                        width = 0.1,
                        order = 18,
                    },
                    screenAnchor = {
                        type = "select",
                        name = "Screen Anchor",
                        values = { TOPLEFT="TOPLEFT", TOP="TOP", TOPRIGHT="TOPRIGHT",
                                LEFT="LEFT", CENTER="CENTER", RIGHT="RIGHT",
                                BOTTOMLEFT="BOTTOMLEFT", BOTTOM="BOTTOM", BOTTOMRIGHT="BOTTOMRIGHT" },
                        get = function() return CT.db.profile.display.screenAnchor end,
                        set = function(_, v) CT.db.profile.display.screenAnchor = v; CurrencyTracker_Mover:Reset() end,
                        order = 20,
                        width = .8,
                    },
                    spacer4= {
                        type = "description",
                        name = " ",
                        width = 0.1,
                        order = 21,
                    },
                    trackerAnchor = {
                        type = "select",
                        name = "Tracker Anchor",
                        values = { TOPLEFT="TOPLEFT", TOP="TOP", TOPRIGHT="TOPRIGHT",
                                LEFT="LEFT", CENTER="CENTER", RIGHT="RIGHT",
                                BOTTOMLEFT="BOTTOMLEFT", BOTTOM="BOTTOM", BOTTOMRIGHT="BOTTOMRIGHT" },
                        get = function() return CT.db.profile.display.trackerAnchor end,
                        set = function(_, v) CT.db.profile.display.trackerAnchor = v; CurrencyTracker_Mover:Reset() end,
                        order = 22,
                        width = .8,
                    },
                    spacer5= {
                        type = "description",
                        name = " ",
                        width = 0.1,
                        order = 23,
                    },
                    reset = {
                        type = "execute",
                        name = "Reset Position",
                        func = function()
                            local d = CT.db.profile.display
                            d.x = 0; d.y = 0
                            d.screenAnchor = "CENTER"; d.trackerAnchor = "CENTER"
                            CurrencyTracker_Mover:Reset()
                        end,
                        order = 19,
                    },
                    unlock = {
                        type = "toggle",
                        name = "Unlock Mover",
                        get = function() return CT.db.profile.display.unlocked end,
                        set = function(_, v) CT.db.profile.display.unlocked = v; CurrencyTracker_Mover:SetUnlocked(v) end,
                        order = 25,
                        width = .8,
                    },

                    -- -------------------------
                    -- Visibility
                    -- -------------------------
                    visibilityHeader = {
                        type = "header",
                        name = "Visibility",
                        order = 30,
                    },
                    hideEmpty = {
                        type = "toggle",
                        name = "Hide Empty",
                        get = function() return CT.db.profile.display.hideEmpty end,
                        set = function(_, v) CT.db.profile.display.hideEmpty = v; CT:RequestUpdate() end,
                        order = 31,
                    },
                    hideInCombat = {
                        type = "toggle",
                        name = "Hide In Combat",
                        get = function() return CT.db.profile.display.hideInCombat end,
                        set = function(_, v) CT.db.profile.display.hideInCombat = v; CT:RequestUpdate() end,
                        order = 32,
                    },
                },
            },


            -- =========================
            -- Currencies Tab
            -- =========================
            currencies = {
                type = "group",
                name = "Currencies",
                order = 2,
                args = {
                    add = {
                        type = "select",
                        name = "Add Currency",
                        order = 1,
                        values = GetAvailableCurrencies,
                        set = function(_, currencyID)
                            currencyID = tonumber(currencyID)
                            CT.db.profile.currencies[currencyID] = {
                                order = GetNextOrder(),
                                color = { r = 1, g = 1, b = 1 },
                            }
                            RebuildTrackedCurrencies()
                            CT:RequestUpdate()
                        end,
                    },
                    tracked = {
                        type = "group",
                        name = "Tracked Currencies",
                        inline = true,
                        order = 2,
                        args = {},
                    },
                },
            },

            -- =========================
            -- Profiles Tab
            -- =========================
            profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(CT.db),
        },
    }

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName)

    RebuildTrackedCurrencies()
end
