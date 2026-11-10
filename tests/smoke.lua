-- Run from the project directory with LuaJIT or Lua 5.1.
local events, screen, chat, sounds, timers = {}, {}, {}, {}, {}
local rollLinks, canNeed, slots = {}, {}, {}
local secret = {}
local loaded = { NeedRoll = true, LevelMates = true, OneForAll = true, AtlasLootClassic = true }
local suffix = "Surname"
local function Link(id, name)
    return ("|cff0070dd|Hitem:%d:0|h[%s]|h|r"):format(id, name)
end

C_AddOns = { IsAddOnLoaded = function(name) return loaded[name] == true end }
C_Timer = { After = function(delay, callback)
    timers[#timers + 1] = { delay = delay, callback = callback }
end }
function issecretvalue(value) return value == secret end
function GetLocale() return "esES" end
function UnitName(unit) assert(unit == "player"); return "Player", suffix end
function GetRealmName() return "Test Realm" end
function GetNormalizedRealmName() return "TestRealm" end
function GetLootRollItemLink(id) assert(type(id) == "number"); return rollLinks[id] end
function GetLootRollItemInfo(id) return nil, nil, nil, nil, nil, canNeed[id] end
function GetNumLootItems() return #slots end
function GetLootSlotLink(slot) return slots[slot] end
SOUNDKIT = { RAID_WARNING = 8959 }
function PlaySound(sound) sounds[#sounds + 1] = sound end
SlashCmdList = {}
RaidWarningFrame, NORMAL_FONT_COLOR = {}, {}
function RaidNotice_AddMessage(frame, message, color)
    assert(frame == RaidWarningFrame and color == NORMAL_FONT_COLOR)
    screen[#screen + 1] = message
end
function print(...) chat[#chat + 1] = table.concat({ ... }, " ") end
function CreateFrame()
    return {
        RegisterEvent = function(_, event) events[event] = true end,
        SetScript = function(self, script, callback) self[script] = callback; events.frame = self end,
    }
end
local function Fire(event, ...)
    assert(events[event])
    events.frame:OnEvent(event, ...)
end
local function Command(args) SlashCmdList.WISHLISTALERTS(args) end
local function Saw(lines, snippet) assert(lines[#lines]:find(snippet, 1, true), lines[#lines]) end

local greedButton = {
    IsEnabled = function() return true end,
    HookScript = function(self, script, callback)
        assert(script == "OnEnter" and not self[script])
        self[script] = callback
    end,
}
GroupLootFrame1 = { LootButtonContainer = { GreedButton = greedButton } }

NeedRollDB = { wishlist = { current = "Second", lists = {
    { name = "First", items = { { itemID = 101 } } },
    { name = "Second", items = { { itemID = 6220, slot = "MAINHAND" } } },
} } }
LevelMatesDB = {
    chars = {
        ["Player Surname-Test Realm"] = { wishes = { { id = 6220 } } },
        ["Player-Test Realm"] = { wishes = { { id = 404 } } },
        ["Other-Test Realm"] = { wishes = { { id = 505 } } },
    },
    wishes = { ["Guild"] = { ["Other"] = { ids = { 606 } } } },
}
OneForAllCharDB = { wishlist = { [6220] = true, [707] = true } }
AtlasLoot = { Addons = { GetAddon = function(_, name)
    assert(name == "Favourites")
    return { IsFavouriteItemID = function(_, id)
        if id == 999 then error("incompatible optional API") end
        return id == 808 and { "active" } or nil
    end }
end } }

local ns = {}
for _, file in ipairs({ "Locale.lua", "Sources.lua", "Alerts.lua" }) do
    assert(loadfile("WishlistAlerts/" .. file))("WishlistAlerts", ns)
end
Fire("START_LOOT_ROLL", 1, 60000) -- before initialization
Fire("ADDON_LOADED", "WishlistAlerts")
Fire("PLAYER_LOGIN")
assert(ns.Matches(6220) == "NeedRoll, Forever Guild, OneForAll")
assert(ns.Matches(808) == "AtlasLoot")
assert(ns.Matches(101) == "" and ns.Matches(404) == "" and ns.Matches(505) == "" and ns.Matches(606) == "")
assert(ns.Matches(999) == "")
suffix = "TestRealm"
assert(ns.Matches(404) == "Forever Guild")
suffix = secret
assert(ns.Matches(404) == "" and ns.Matches(6220) == "NeedRoll, OneForAll")
suffix = "Surname"
loaded.OneForAll = false
assert(ns.Matches(707) == "")
loaded.OneForAll = true
NeedRollDB.wishlist.current = "missing"
assert(ns.Matches(101) == "NeedRoll")
NeedRollDB.wishlist.current = "Second"

local dagger = Link(6220, "Fragmento de meteorito")
C_Item = { GetItemInfo = function(value)
    if value == 6220 or value == "Fragmento de meteorito" then
        return "Fragmento de meteorito", dagger
    end
end }
Command("check Fragmento de meteorito")
Saw(chat, "ID 6220")
Saw(chat, "NeedRoll, Forever Guild, OneForAll")
Command("check [Fragmento de meteorito]")
Saw(chat, "ID 6220")
Command("check Nombre desconocido")
Saw(chat, "WoW no reconoce ese nombre")

Command("comprobar 6220")
Saw(chat, "NeedRoll, Forever Guild, OneForAll")
Command("check " .. dagger)
Saw(chat, "ID 6220")
Saw(chat, "NeedRoll, Forever Guild, OneForAll")
Command("check 505")
Saw(chat, "no está en tus listas")
assert(#screen == 0 and #sounds == 0)

rollLinks[1], canNeed[1] = dagger, true
Fire("START_LOOT_ROLL", 1, 60000)
Saw(screen, "Considera tirar Necesidad")
Saw(chat, "NeedRoll, Forever Guild, OneForAll")
assert(#screen == 1 and #sounds == 1 and timers[1].delay == 60)
Fire("START_LOOT_ROLL", 1, 60000)
GroupLootFrame1.rollID = 1
greedButton:OnEnter()
greedButton:OnEnter()
Saw(screen, "Antes de tirar Codicia")
assert(#screen == 2 and #sounds == 1)

Fire("CANCEL_LOOT_ROLL", 1)
rollLinks[1], canNeed[1] = dagger, false
Fire("START_LOOT_ROLL", 1, 60000)
timers[1].callback()
Saw(screen, "Necesidad no está disponible")
greedButton:OnEnter()
assert(#screen == 3 and #sounds == 2)

Fire("START_LOOT_ROLL", 2, 60000)
assert(timers[#timers].delay == 0.15)
rollLinks[2], canNeed[2] = dagger, secret
timers[#timers].callback()
Saw(screen, "está en tus deseos.")
assert(#screen == 4)
rollLinks[3] = secret
Fire("START_LOOT_ROLL", 3, 60000)
assert(timers[#timers].delay == 60 and #screen == 4)
Fire("START_LOOT_ROLL", secret, 60000)

Command("sound off")
slots = { dagger, secret, Link(808, "Favorito") }
Fire("LOOT_READY")
Fire("LOOT_OPENED")
assert(#screen == 6 and #sounds == 3)
Saw(screen, "Favorito")
Fire("LOOT_CLOSED")
Fire("LOOT_OPENED")
assert(#screen == 8)
Command("loot off")
Fire("LOOT_CLOSED")
Fire("LOOT_OPENED")
assert(#screen == 8)
Command("greed off")
rollLinks[4], canNeed[4] = dagger, true
Fire("START_LOOT_ROLL", 4, 60000)
GroupLootFrame1.rollID = 4
greedButton:OnEnter()
assert(#screen == 9)
Fire("CANCEL_ALL_LOOT_ROLLS")
Command("off")
Fire("START_LOOT_ROLL", 4, 60000)
assert(#screen == 9)
Command("prueba")
assert(#screen == 10 and #sounds == 3)
Fire("ADDON_LOADED", "WishlistAlerts")
assert(not WishlistAlertsDB.enabled and not WishlistAlertsDB.greed and not WishlistAlertsDB.sound and not WishlistAlertsDB.loot)
io.write("OK: four source adapters, local alerts, Greed hover, duplicates, restricted data, and settings\n")

-- Check all client locales and the default through the same bootstrap and slash handler.
local function LoadUI(locale)
    GetLocale = function() return locale end
    local addon = {}
    for _, file in ipairs({ "Locale.lua", "Sources.lua", "Alerts.lua" }) do
        assert(loadfile("WishlistAlerts/" .. file))("WishlistAlerts", addon)
    end
    Fire("ADDON_LOADED", "WishlistAlerts")
    return addon.Text
end

assert(SLASH_WISHLISTALERTS1 == "/wla" and SLASH_WISHLISTALERTS2 == "/wishlistalerts")
local english = LoadUI("enUS")
for _, locale in ipairs({ "enUS", "esES", "esMX", "deDE", "frFR", "ptBR", "ruRU", "koKR", "zhCN", "zhTW", "unknown" }) do
    local translation = LoadUI(locale)
    for key, original in pairs(english) do
        local phrase = rawget(translation, key)
        assert(type(phrase) == "string" and #phrase > 0, locale .. ": " .. key)
        local function Specifiers(text)
            local formats = {}
            for specifier in text:gmatch("%%[sd]") do formats[#formats + 1] = specifier end
            return table.concat(formats)
        end
        assert(Specifiers(phrase) == Specifiers(original), locale .. ": " .. key)
    end
    if locale == "enUS" or locale == "unknown" then
        assert(translation.test == english.test)
    else
        assert(translation.test ~= english.test)
    end
    Command("test")
    Saw(screen, translation.test)
    Command("check 6220")
    Saw(chat, translation.sources:format("NeedRoll, Forever Guild, OneForAll"))
    Command("check")
    Saw(chat, "/wla check " .. translation.item)
    WishlistAlertsDB.enabled = true
    WishlistAlertsDB.sound = false
    WishlistAlertsDB.loot = true
    WishlistAlertsDB.greed = false
    local help
    for _, alias in ipairs({ "", "help", "info", "desconocido", "anything with arguments" }) do
        local start = #chat
        Command(alias)
        assert(#chat == start + 8)
        assert(chat[start + 1] == "Wishlist Alerts — " .. translation.commands .. " (/wla)")
        assert(chat[start + 2]:find("[" .. translation.on .. "]", 1, true))
        assert(chat[start + 3]:find("[" .. translation.off .. "]", 1, true))
        assert(chat[start + 5]:find("/wla greed on · /wla greed off", 1, true))
        assert(chat[start + 5]:find(translation.helpGreed, 1, true))
        assert(chat[start + 7]:find(translation.helpDemo, 1, true))
        Saw(chat, "/wla check " .. translation.item)
        local output = table.concat(chat, "\n", start + 1, #chat)
        assert(not help or help == output)
        help = output
    end

    local before = #chat
    Command("greed on")
    assert(WishlistAlertsDB.greed == true and #chat == before + 1)
    Saw(chat, translation.greedOption .. ": " .. translation.on)
    Command("greed off")
    assert(WishlistAlertsDB.greed == false and #chat == before + 2)
    Saw(chat, translation.greedOption .. ": " .. translation.off)
end
io.write("OK: /wla and all ten client locales, plus English fallback\n")

-- The demo uses only its own buttons and follows the real alert preferences.
local CreateEventFrame = CreateFrame
local demo, buttons = nil, {}
NEED, GREED, PASS = "Necesidad", "Codicia", "Clave"
function CreateFrame(kind, name, parent, template)
    if not template then return CreateEventFrame() end
    local widget = {
        SetSize = function() end,
        SetPoint = function() end,
        SetFrameStrata = function() end,
        SetText = function(self, label) self.label = label end,
        SetScript = function(self, script, callback) self[script] = callback end,
        Show = function(self) self.shown = true end,
        Hide = function(self) self.shown = false end,
    }
    if kind == "Frame" then
        demo = widget
        widget.TitleText = { SetText = widget.SetText }
        widget.CreateFontString = function() return { SetPoint = widget.SetPoint, SetText = widget.SetText } end
    else
        assert(kind == "Button" and parent == demo and template == "UIPanelButtonTemplate")
        buttons[#buttons + 1] = widget
    end
    return widget
end

LoadUI("esES")
Command("on")
Command("sound on")
Command("greed on")
local beforeScreen, beforeSound = #screen, #sounds
Command("demo")
assert(demo.shown and #buttons == 3 and #screen == beforeScreen + 1 and #sounds == beforeSound + 1)
Saw(screen, "Considera tirar Necesidad")
assert(buttons[3].label == "Pasar")
buttons[2].OnEnter()
buttons[2].OnEnter()
assert(#screen == beforeScreen + 2 and #sounds == beforeSound + 1)
Saw(screen, "Antes de tirar Codicia")
for _, button in ipairs(buttons) do
    local count = #screen
    button.OnClick()
    assert(not demo.shown and #screen == count)
    Saw(chat, "Tirada de botín simulada — " .. button.label)
    Command("demo")
end
Command("greed off")
Command("sound off")
beforeScreen, beforeSound = #screen, #sounds
Command("demo")
buttons[2].OnEnter()
assert(#screen == beforeScreen + 1 and #sounds == beforeSound and #buttons == 3)
Command("off")
beforeScreen = #screen
Command("demo")
buttons[2].OnEnter()
assert(demo.shown and #screen == beforeScreen)
io.write("OK: demo buttons, alert timing, and settings\n")

-- The native Settings panel and slash commands use the same SavedVariables.
local category, controls, registrations = {}, {}, 0
Settings = {
    VarType = { Boolean = "boolean" },
    RegisterVerticalLayoutCategory = function(name)
        assert(name == "Wishlist Alerts")
        return category
    end,
    RegisterAddOnSetting = function(panel, variable, key, database, valueType, label, default)
        assert(panel == category and variable == "WishlistAlerts_" .. key)
        assert(database == WishlistAlertsDB and valueType == "boolean" and default == true)
        return {
            key = key,
            label = label,
            GetValue = function() return database[key] end,
            SetValue = function(_, value) database[key] = value end,
        }
    end,
    CreateCheckbox = function(panel, setting, description)
        assert(panel == category and not controls[setting.key])
        controls[setting.key] = { setting = setting, description = description }
    end,
    RegisterAddOnCategory = function(panel)
        assert(panel == category)
        registrations = registrations + 1
    end,
}
local spanish = LoadUI("esES")
assert(registrations == 1)
assert(controls.enabled.setting.label == spanish.alerts)
assert(controls.sound.setting.label == spanish.sound)
assert(controls.loot.description == spanish.helpLoot)
assert(controls.greed.description == spanish.helpGreed)
local greed = controls.greed.setting
assert(not greed:GetValue())
Command("greed on")
assert(greed:GetValue())
greed:SetValue(false)
Command("DESCONOCIDO")
assert(chat[#chat - 3]:find("[" .. spanish.off .. "]", 1, true))
Fire("ADDON_LOADED", "WishlistAlerts")
assert(registrations == 1 and not greed:GetValue())
io.write("OK: native Settings registration, shared state, and unknown command help\n")
