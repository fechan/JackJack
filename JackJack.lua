-- set addon namespace
local addonName, addon = ...

-- set up Ace addon object
local Ace = LibStub("AceAddon-3.0"):NewAddon("JackJack", "AceConsole-3.0")

function Ace:OnInitialize ()
    addon:initGUI()
end

--- Get all locations that (fuzzy) match the location name
-- @param locationName  Location name to match
-- @param limit         (optional) Limit to this number of locations
function addon:locationsMatching(locationName, limit)
    local matchingLocations = {}
    local matches = 0
    limit = limit or math.huge

    for rowNumber, poi in pairs(addon.JJAreaPOI) do
        local match = {}
        if addon.fzy.has_match(locationName, poi["Name_lang"])
                and matches < limit then
            -- significantly faster to precompute score and put it in memory than
            -- computing every time a comparison is made in the sort
            match["fzyScore"] = addon.fzy.score(locationName, poi["Name_lang"])
            match["Name_lang"] = poi["Name_lang"]
            match["Pos0"] = poi["Pos0"]
            match["Pos1"] = poi["Pos1"]
            match["ContinentID"] = poi["ContinentID"]
            match["AreaName_lang"] = poi["AreaName_lang"]
            match["Description_lang"] = poi["Description_lang"]
            match["MapName_lang"] = addon.JJMap[poi["ContinentID"]]["MapName_lang"]
            match["Origin"] = "AreaPOI (Points of Interest table)"
            table.insert(matchingLocations, match)
            matches = matches + 1
        end
    end

    -- sort by how close the match is to the location name
    table.sort(matchingLocations, function(a, b)
        return a["fzyScore"] > b["fzyScore"]
    end)

    return matchingLocations
end

Ace:RegisterChatCommand("jjsearch", function (query)
    for idx, location in ipairs(addon:locationsMatching(query, 20)) do
        Ace:Print(location["Name_lang"])
    end
end)