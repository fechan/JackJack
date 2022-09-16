-- set addon namespace
local addonName, addon = ...

-- set up Ace addon object
local Ace = LibStub("AceAddon-3.0"):NewAddon("JackJack", "AceConsole-3.0")

---=== ADDON STATE ===---
-- You should declare any state vars that are global to the addon
-- here even if they start out as nil, so we have a quick reference to them
addon.AddonState = {
    ["directions"] = nil, -- current set of directions currently active
    ["directionWaypoints"] = {},
}

---=== DATA FUNCTIONS ===---

--- Get all locations that (fuzzy) match the location name
-- @param locationName  Location name to match
-- @param limit         (optional) Limit to this number of locations
-- @param sameInstance  (optional) Only include non-instanced locations and locations in the same instance as the player
function addon:locationsMatching(locationName, limit, sameInstance)
    sameInstance = sameInstance or true

    local matchingLocations = {}
    local matches = 0
    limit = limit or math.huge

    -- TODO: use metatables for lua data sets for Origin (and maybe even ContinentID)

    local datasetOrigins = {
        "AreaPOI (Points of Interest table)",
        "TaxiNodes (Flight points table)",
    }
    for datasetNbr, dataset in pairs({addon.JJAreaPOI, addon.JJTaxiNodes}) do
        for rowNumber, poi in pairs(dataset) do
            if ((not sameInstance) or (addon.JJMap[poi.ContinentID].InstanceType == 0) or (getPlayerInstance() == poi.ContinentID)) and
                    addon.fzy.has_match(locationName, poi.Name_lang) then
                -- significantly faster to precompute score and put it in memory than
                -- computing every time a comparison is made in the sort
                local match = {
                    ["fzyScore"] = addon.fzy.score(locationName, poi["Name_lang"]),
                    ["Name_lang"] = poi["Name_lang"],
                    ["Pos0"] = poi["Pos0"],
                    ["Pos1"] = poi["Pos1"],
                    ["ContinentID"] = poi["ContinentID"],
                    ["AreaName_lang"] = poi["AreaName_lang"],
                    ["Description_lang"] = poi["Description_lang"],
                    ["MapName_lang"] = addon.JJMap[poi["ContinentID"]]["MapName_lang"],
                    ["Origin"] = datasetOrigins[datasetNbr]
                }                   

                table.insert(matchingLocations, match)
                matches = matches + 1
            end
        end
    end

    -- sort by how close the match is to the location name
    table.sort(matchingLocations, function(a, b)
        return a["fzyScore"] > b["fzyScore"]
    end)

    matchingLocations = table.slice(matchingLocations, 1, limit)

    return matchingLocations
end

--- Try to find the location of the waypoint at a higher zoom level than the given map
-- @param uiMapId       Map ID of the (possibly) lower zoom level map
-- @param initialx      X position of the waypoint on the lower zoom level map
-- @param initialy      Y Position of the waypoint on the lower zoom level map
-- @return uiMapId      Map ID of the higher zoom level map if available, otherwise same as input
-- @return x            X coordinate of the waypoint on the higher zoom level map if available, otherwise same as initialx
-- @return y            Y coordinate of the waypoint on the higher zoom level map if available, otherwise same as initialy
local function getHigherZoomMapPosition(uiMapId, initialx, initialy)
    local x = initialx
    local y = initialy
    local childMapInfo = C_Map.GetMapInfoAtPosition(uiMapId, initialx, initialy)
    if childMapInfo then
        local left, right, top, bottom = C_Map.GetMapRectOnMap(childMapInfo.mapID, uiMapId)
        x = (initialx - left) / (right - left)
        y = (initialy - top) / (bottom - top)
        uiMapId = childMapInfo.mapID
    end
    return uiMapId, x, y
end

--- Try to find the location of the waypoint at the highest possible level of map zoom
-- @param location      Game location to get a waypoint location for
--      @param location.ContinentID Continent ID
--      @param location.Pos0        x coordinate
--      @param location.Pos1        y coordinate
-- @return uiMapId      Map ID of the highest zoom level mapID
-- @return x            X coordinate of the waypoint
-- @return y            Y coordinate of the waypoint
function addon:getBestZoomMapPositionFor(location)
    -- TODO: make this recursive
    local globalCoords = CreateVector2D(location.Pos0, location.Pos1)
    local uiMapId, mapPosition = C_Map.GetMapPosFromWorldPos(location.ContinentID, globalCoords)
    local uiMapId, x, y = getHigherZoomMapPosition(uiMapId, mapPosition.x, mapPosition.y)
    return uiMapId, x, y
end

---=== INITIALIZE ADDON GUI AND COMMANDS ===---

function Ace:OnInitialize ()
    addon:initGUI()
end

Ace:RegisterChatCommand("jjsearch", function (query)
    for idx, location in ipairs(addon:locationsMatching(query, 20)) do
        Ace:Print(location.Name_lang)
    end
end)