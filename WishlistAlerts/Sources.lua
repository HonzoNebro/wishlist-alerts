local _, ns = ...

function ns.Plain(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end

local function Table(value)
    if type(value) == "table" then return value end
end

local function HasEntry(items, field, itemID)
    if not Table(items) then return false end
    for _, entry in ipairs(items) do
        if Table(entry) and entry[field] == itemID then return true end
    end
    return false
end

local function NeedRollList()
    local db = Table(NeedRollDB)
    local wishlist = db and Table(db.wishlist)
    local lists = wishlist and Table(wishlist.lists)
    if not lists then return end
    for _, list in ipairs(lists) do
        if Table(list) and list.name == wishlist.current then return list end
    end
    return Table(lists[1])
end

local function NormalizedRealm(name)
    return (name or ""):lower():gsub("[^%w]", "")
end

-- In Forever UnitName can return the surname in its second result.
-- LevelMates keys its personal data by full name and the displayed realm.
local function ForeverGuildWishes()
    local db = Table(LevelMatesDB)
    local characters = db and Table(db.chars)
    if not characters then return end

    local name, suffix = UnitName("player")
    if issecretvalue and issecretvalue(suffix) then return end
    name = ns.Plain(name)
    local realm = ns.Plain(GetRealmName())
    if not name or not realm then return end
    if suffix and suffix ~= "" then
        local normalized = NormalizedRealm(suffix)
        local alternateRealm = GetNormalizedRealmName and ns.Plain(GetNormalizedRealmName())
        if normalized ~= NormalizedRealm(realm) and normalized ~= NormalizedRealm(alternateRealm) then
            name = name .. " " .. suffix
        end
    end

    local character = Table(characters[name .. "-" .. realm])
    return character and character.wishes
end

local function AtlasLootHas(itemID)
    local atlas = Table(AtlasLoot)
    local addons = atlas and Table(atlas.Addons)
    if not addons or type(addons.GetAddon) ~= "function" then return false end
    local ok, favourites = pcall(addons.GetAddon, addons, "Favourites")
    if not ok or not Table(favourites) or type(favourites.IsFavouriteItemID) ~= "function" then return false end
    local read, match = pcall(favourites.IsFavouriteItemID, favourites, itemID)
    return read and match
end

local sources = {
    { addon = "NeedRoll", label = "NeedRoll", has = function(itemID)
        local list = NeedRollList()
        return list and HasEntry(list.items, "itemID", itemID)
    end },
    { addon = "LevelMates", label = "Forever Guild", has = function(itemID)
        return HasEntry(ForeverGuildWishes(), "id", itemID)
    end },
    { addon = "OneForAll", label = "OneForAll", has = function(itemID)
        local db = Table(OneForAllCharDB)
        local wishlist = db and Table(db.wishlist)
        return wishlist and wishlist[itemID] == true
    end },
    { addon = "AtlasLootClassic", label = "AtlasLoot", has = AtlasLootHas },
}

function ns.Matches(itemID)
    local matches = {}
    for _, source in ipairs(sources) do
        if C_AddOns.IsAddOnLoaded(source.addon) and source.has(itemID) then
            matches[#matches + 1] = source.label
        end
    end
    return table.concat(matches, ", ")
end
