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
    ["jjsearchResults"] = nil,
}

---=== DATA FUNCTIONS ===---

local function getPlayerInstance()
    local _, _, _, _, _, _, _, instanceId = GetInstanceInfo()
    return instanceId
end

--- Get all locations that (fuzzy) match the location name
-- @param locationName  Location name to match
-- @param limit         (optional) Limit to this number of locations
-- @param sameInstance  (optional) Only include non-instanced locations and locations in the same instance as the player
function addon:locationsMatching(locationName, limit, sameInstance)
    if sameInstance == nil then
        sameInstance = true
    end

    local matchingLocations = {}
    local matches = 0
    limit = limit or math.huge

    local datasetOrigins = {
        "AreaPOI (Points of Interest table)",
        "TaxiNodes (Flight points table)",
    }
    for datasetNbr, dataset in pairs({addon.JJAreaPOI, addon.JJTaxiNodes}) do
        for rowNumber, poi in pairs(dataset) do
            local mapForPoi = addon.JJMap[poi.ContinentID]
            -- TODO: checking that mapForPoi exists before adding excludes any POIs whose FK into ContinentID doesn't exist
            --       I might want to enforce this in the data processing side with an inner join or something instead
            if (mapForPoi and ((not sameInstance) or (mapForPoi.InstanceType == 0) or (getPlayerInstance() == poi.ContinentID))) and
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
                    ["InstanceType"] = addon.JJMap[poi["ContinentID"]]["InstanceType"],
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

    return matchingLocations, matches
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
    local globalCoords = CreateVector2D(location.Pos0, location.Pos1)
    local uiMapId, mapPosition = C_Map.GetMapPosFromWorldPos(location.ContinentID, globalCoords)
    local x, y = mapPosition.x, mapPosition.y
    while true do
        local newUiMapId, newX, newY = getHigherZoomMapPosition(uiMapId, x, y)

        if newUiMapId == uiMapId then
            break
        else
            uiMapId, x, y = newUiMapId, newX, newY
        end
    end
    return uiMapId, x, y
end

---=== COMMAND HANDLERS ===---
local function jackjack(mainwindow)
    if WorldMapFrame:IsVisible() then
        if addon.Settings.profile.gui.closed then
            mainwindow:Show()
            addon.Settings.profile.gui.closed = false
        else
            WorldMapFrame:Hide()
        end
    else
        WorldMapFrame:Show()
        mainwindow:Show()
        addon.Settings.profile.gui.closed = false
    end
end

local function jjsearch(query)
    local results = addon:locationsMatching(query, 8)
    if #results > 0 then
        Ace:Print("Search results for: " .. query)

        addon.AddonState.jjsearchResults = results
        for idx, location in ipairs(results) do
            Ace:Print(idx .. ": " .. location.Name_lang)
        end
    else
        Ace:Print("Could not find any locations matching: " .. query)
    end
end

local function jjset(query)
    local selection = tonumber(query, 10) -- if the query is a number, then this returns an int instead of nil
    if selection then
        if addon.AddonState.jjsearchResults then
            local selectedLocation = addon.AddonState.jjsearchResults[selection]
            if selectedLocation then
                addon:createWaypointFor(selectedLocation)
                Ace:Print("Added a waypoint to: " .. selectedLocation.Name_lang)
            else
                Ace:Print("No location numbered " .. selection .. " in last /jjsearch!")
            end
        else
            Ace:Print("You need to search for locations with /jjsearch <location> first!")
        end
    else
        local result = addon:locationsMatching(query, 1)[1]
        if result then
            Ace:Print("Added a waypoint to: " .. result.Name_lang)
            addon:createWaypointFor(result)
        else
            Ace:Print("Could not find any locations matching: " .. query)
        end
    end
end

---=== INITIALIZE ADDON GUI AND COMMANDS ===---

local function initCommands(mainwindow)
    Ace:RegisterChatCommand("jj", function (query) jackjack(mainwindow) end)
    Ace:RegisterChatCommand("jackjack", function (query) jackjack(mainwindow) end)
    
    Ace:RegisterChatCommand("jjsearch", jjsearch)

    Ace:RegisterChatCommand("jjset", jjset)
end

function Ace:OnInitialize ()
    addon.Settings = LibStub("AceDB-3.0"):New("JackJackSettings", {
        profile = {
            showInstances = true,
            gui = {
                maximizedHeight = 500,
                minimized = false,
                closed = false
            },
            waypoints = {
                autoRemove = true
            },
            directions = {
                includeTaxi = true,
                loadingScreenSeconds = 10
            }
        }
    })

    local aceConfigOptions = {
        name = "JackJack",
        handler = addon,
        type = "group",
        args = {
            directions = {
                name = "Directions",
                type = "group",
                args = {
                    includeTaxi = {
                        name = "Include flight points in directions",
                        desc = "This makes calculating directions MUCH slower, but more accurate and with flight directions.",
                        type = "toggle",
                        width = "full",
                        set = function(info, val) addon.Settings.profile.directions.includeTaxi = val end,
                        get = function(info) return addon.Settings.profile.directions.includeTaxi end
                    },
                    loadingScreenSeconds = {
                        name = "Average loading screen time (seconds)",
                        desc = "JackJack takes loading screens into account when calculating directions. \n" ..
                        "It will try to avoid loading screens if it would make your journey longer.",
                        type = "range",
                        min = 0,
                        softMax = 180,
                        bigStep = 1,
                        width = "full",
                        set = function(info, val) addon.Settings.profile.directions.loadingScreenSeconds = tonumber(val) end,
                        get = function(info) return addon.Settings.profile.directions.loadingScreenSeconds end
                    }
                }
            },
            waypoints = {
                name = "Waypoints",
                type = "group",
                args = {
                    autoRemoveWaypoints = {
                        name = "Auto remove direction waypoints",
                        desc = "Auto remove direction waypoints when you're closer to a more advanced waypoint. \n\n" ..
                               "e.g. There are steps 1-4 in the directions, but you skipped all the way to 3, so 1 and 2 are autoremoved.",
                        type = "toggle",
                        width = "full",
                        set = function(info, val) addon.Settings.profile.waypoints.autoRemove = val end,
                        get = function(info) return addon.Settings.profile.waypoints.autoRemove end
                    }
                }
            }
        }

    }

    LibStub("AceConfig-3.0"):RegisterOptionsTable("JackJack", aceConfigOptions, {"jjconfig"})

    local profileChanger = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.Settings)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("JackJackProfiles", profileChanger, nil)

    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("JackJack", "JackJack", nil);
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("JackJackProfiles", "Profiles", "JackJack");

    addon:initWaypoints()
    local mainwindow = addon:initGUI()
    initCommands(mainwindow)
    addon:createMinimapButton(function () jackjack(mainwindow) end)
end