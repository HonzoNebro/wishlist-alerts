local addonName, ns = ...
local Plain = ns.Plain
local text = ns.Text

local defaults = { enabled = true, sound = true, loot = true, greed = true }
local settings
local menuSettings = {}
local optionKeys = { "enabled", "sound", "loot", "greed" }
local options = {
    enabled = { label = text.alerts, description = text.helpEnabled },
    sound = { label = text.sound, description = text.helpSound },
    loot = { label = text.lootOption, description = text.helpLoot },
    greed = { label = text.greedOption, description = text.helpGreed },
}

local function RegisterOptions()
    if not Settings or next(menuSettings) then return end
    local category = Settings.RegisterVerticalLayoutCategory("Wishlist Alerts")
    for _, key in ipairs(optionKeys) do
        local option = options[key]
        local setting = Settings.RegisterAddOnSetting(category, addonName .. "_" .. key,
            key, settings, Settings.VarType.Boolean, option.label, defaults[key])
        menuSettings[key] = setting
        Settings.CreateCheckbox(category, setting, option.description)
    end
    Settings.RegisterAddOnCategory(category)
end

local function SetOption(key, value)
    local setting = menuSettings[key]
    if setting then
        setting:SetValue(value)
    else
        settings[key] = value
    end
end
local rolls, lootSlots = {}, {}
local hookedGreedButtons = {}

local function ItemID(link)
    if type(link) == "string" then return tonumber(link:match("|Hitem:(%d+)")) end
end

local function Match(link)
    local id = ItemID(link)
    if not id then return end
    local sources = ns.Matches(id)
    if sources ~= "" then return sources, link:match("|h%[(.-)%]|h") or tostring(id) end
end

local function Screen(message)
    if RaidWarningFrame and RaidNotice_AddMessage and NORMAL_FONT_COLOR then
        RaidNotice_AddMessage(RaidWarningFrame, message, NORMAL_FONT_COLOR)
    elseif UIErrorsFrame then
        UIErrorsFrame:AddMessage(message, 1, 0.82, 0)
    end
end

local function Sound()
    if settings.sound and SOUNDKIT and SOUNDKIT.RAID_WARNING then
        PlaySound(SOUNDKIT.RAID_WARNING)
    end
end

local function Announce(message, name, link, sources)
    Screen(message:format(name))
    print("Wishlist Alerts", message:format(link), "(" .. sources .. ")")
    Sound()
end

local function CheckRoll(rollID, roll)
    if not settings.enabled or rolls[rollID] ~= roll or roll.announced then return end
    local rawLink = GetLootRollItemLink(rollID)
    local link = Plain(rawLink)
    local sources, name = Match(link)
    if not sources then
        return type(link) == "nil" and not (issecretvalue and issecretvalue(rawLink))
    end

    local canNeed = Plain((select(6, GetLootRollItemInfo(rollID))))
    local message = text.roll
    if canNeed == true then message = text.need end
    if canNeed == false then message = text.noNeed end
    roll.announced = true
    Announce(message, name, link, sources)
end

local function StartRoll(rollID, duration)
    rollID, duration = Plain(rollID), Plain(duration)
    if not settings.enabled or type(rollID) ~= "number" or rolls[rollID] then return end

    local roll = {}
    rolls[rollID] = roll
    local seconds = type(duration) == "number" and duration > 0 and duration / 1000 or 60
    C_Timer.After(seconds, function()
        if rolls[rollID] == roll then rolls[rollID] = nil end
    end)
    if CheckRoll(rollID, roll) and seconds > 0.15 then
        C_Timer.After(0.15, function() CheckRoll(rollID, roll) end)
    end
end

local function ShowGreedReminder(roll, name)
    roll.reminded = true
    Screen(text.greed:format(name))
end

local function OnGreedHover(button, frame)
    if not settings.enabled or not settings.greed or Plain(button:IsEnabled()) ~= true then return end
    local rollID = Plain(frame.rollID)
    if type(rollID) ~= "number" then return end
    local roll = rolls[rollID]
    if not roll or roll.reminded then return end
    if Plain((select(6, GetLootRollItemInfo(rollID)))) ~= true then return end

    local sources, name = Match(Plain(GetLootRollItemLink(rollID)))
    if sources then ShowGreedReminder(roll, name) end
end

local function HookGreedButtons()
    -- Forever's native desktop roll frames. Observe hover, leaving OnClick to Blizzard.
    for index = 1, 4 do
        local frame = _G["GroupLootFrame" .. index]
        local container = frame and frame.LootButtonContainer
        local button = frame and (container and container.GreedButton or frame.GreedButton)
        if button and not hookedGreedButtons[button] then
            button:HookScript("OnEnter", function(self) OnGreedHover(self, frame) end)
            hookedGreedButtons[button] = true
        end
    end
end

local function ScanLoot()
    if not settings.enabled or not settings.loot then return end
    local count = Plain(GetNumLootItems())
    if type(count) ~= "number" then return end

    for slot = 1, count do
        local link = Plain(GetLootSlotLink(slot))
        local id = ItemID(link)
        if id and lootSlots[slot] ~= id then
            local sources, name = Match(link)
            if sources then
                lootSlots[slot] = id
                Announce(text.loot, name, link, sources)
            end
        end
    end
end

local frame = CreateFrame("Frame")
local handlers = {
    ADDON_LOADED = function(loaded)
        if loaded == addonName then
            if type(WishlistAlertsDB) ~= "table" then WishlistAlertsDB = {} end
            settings = WishlistAlertsDB
            for key, value in pairs(defaults) do
                if type(settings[key]) ~= "boolean" then settings[key] = value end
            end
            RegisterOptions()
        elseif loaded == "Blizzard_UIPanels_Game" then
            HookGreedButtons()
        end
    end,
    PLAYER_LOGIN = function()
        RegisterOptions()
        HookGreedButtons()
    end,
    START_LOOT_ROLL = function(...)
        HookGreedButtons()
        StartRoll(...)
    end,
    CANCEL_LOOT_ROLL = function(rollID)
        rollID = Plain(rollID)
        if type(rollID) == "number" then rolls[rollID] = nil end
    end,
    CANCEL_ALL_LOOT_ROLLS = function() rolls = {} end,
    LOOT_READY = ScanLoot,
    LOOT_OPENED = ScanLoot,
    LOOT_CLOSED = function() lootSlots = {} end,
}
for event in pairs(handlers) do frame:RegisterEvent(event) end
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" or settings then handlers[event](...) end
end)

local function CheckCommand(argument)
    if argument == "" then
        print("Wishlist Alerts", "/wla check " .. text.item)
        return
    end

    local link = argument:match("(|Hitem:[^|]+|h.-|h)")
    local id = ItemID(link) or tonumber(argument)
    if not id then
        local name = argument:match("^%[(.+)%]$") or argument
        link = Plain((select(2, C_Item.GetItemInfo(name))))
        id = ItemID(link)
    end
    if not id or id < 1 or id % 1 ~= 0 or id > 2147483647 then
        print("Wishlist Alerts", text.unknownItem)
        return
    end

    link = link or Plain((select(2, C_Item.GetItemInfo(id))))
    local sources = ns.Matches(id)
    local message = sources == "" and text.none or text.sources:format(sources)
    local item = ("ID %d"):format(id)
    if type(link) == "string" then item = ("%s (%s)"):format(link, item) end
    print("Wishlist Alerts", item, "—", message)
end

local function OptionStatus(key)
    local state = settings[key] and text.on or text.off
    return ("%s: %s"):format(options[key].label, state)
end

local demo, demoRoll

local function ShowDemo()
    if not demo then
        demo = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
        demo:SetSize(390, 115)
        demo:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
        demo:SetFrameStrata("DIALOG")
        demo.TitleText:SetText(text.demo)

        local item = demo:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        item:SetPoint("TOP", 0, -40)
        item:SetText(text.demoItem)

        local choices = { NEED or "Need", GREED or "Greed", text.demoPass }
        for index, label in ipairs(choices) do
            local button = CreateFrame("Button", nil, demo, "UIPanelButtonTemplate")
            button:SetSize(112, 25)
            button:SetPoint("BOTTOM", (index - 2) * 120, 16)
            button:SetText(label)
            button:SetScript("OnClick", function()
                demo:Hide()
                print("Wishlist Alerts", text.demo, "—", label)
            end)
            if index == 2 then
                button:SetScript("OnEnter", function()
                    if settings.enabled and settings.greed and not demoRoll.reminded then
                        ShowGreedReminder(demoRoll, text.demoItem)
                    end
                end)
            end
        end
    end

    demoRoll = {}
    demo:Show()
    if settings.enabled then
        Screen(text.need:format(text.demoItem))
        Sound()
    end
end

local function HelpOption(key, command)
    local badge = settings[key] and ("|cff79c8ff[%s]|r"):format(text.on)
        or ("|cffffce80[%s]|r"):format(text.off)
    print(badge, command .. " on · " .. command .. " off", "—", options[key].description)
end

local function ShowHelp()
    print("Wishlist Alerts", "—", text.commands, "(/wla)")
    HelpOption("enabled", "/wla")
    for _, key in ipairs({ "sound", "loot", "greed" }) do
        HelpOption(key, "/wla " .. key)
    end
    print("/wla test", "—", text.helpTest)
    print("/wla demo", "—", text.helpDemo)
    print("/wla check " .. text.item, "—", text.helpCheck)
end

SLASH_WISHLISTALERTS1 = "/wla"
SLASH_WISHLISTALERTS2 = "/wishlistalerts"
SlashCmdList.WISHLISTALERTS = function(message)
    local command, argument = message:match("^%s*(%S*)%s*(.-)%s*$")
    command = command:lower()
    if command == "check" or command == "comprobar" then
        CheckCommand(argument)
        return
    end
    if command == "demo" then
        ShowDemo()
        return
    end
    if command == "test" or command == "prueba" then
        Screen(text.test)
        print("Wishlist Alerts", text.test)
        Sound()
        return
    end

    if command == "on" or command == "off" then
        SetOption("enabled", command == "on")
        print("Wishlist Alerts", OptionStatus("enabled"))
    elseif defaults[command] and (argument == "on" or argument == "off") then
        SetOption(command, argument == "on")
        print("Wishlist Alerts", OptionStatus(command))
    else
        ShowHelp()
    end
end
