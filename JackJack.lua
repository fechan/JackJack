-- set addon namespace
local addonName, addon = ...

-- slash commands
SLASH_JACKJACK1 = "/jackjack"
SLASH_JACKJACK2 = "/jj"
SLASH_JJRESET1 = "/jjreset"

-- sizing for frames
-- TODO: these are temporary until I move all the UI code to JackJackUI.lua
JJ_WIDTH = addon.UI_CONSTS.WIDTH
JJ_HEIGHT = addon.UI_CONSTS.CONTENT_HEIGHT
JJ_MARGIN = addon.UI_CONSTS.MARGIN
JJ_SCROLLBAR_REGION_WIDTH = addon.UI_CONSTS.SCROLLBAR_REGION_WIDTH
JJ_DIRECTIONS_BUTTON_WIDTH = addon.UI_CONSTS.DIRECTIONS_BUTTON_WIDTH
JJ_BUTTON_WIDTH = addon.UI_CONSTS.BUTTON_WIDTH
JJ_BUTTON_HEIGHT = addon.UI_CONSTS.BUTTON_HEIGHT

--- Set the text that displays the number of search results accordingly
-- @param numResults the number of search results
local function setSearchResultsText(numResults)
    if numResults == 0 then
        JJ_SEARCH_RESULTS_TXT:SetText("No possible matching locations found!")
    elseif numResults < 20 then
        JJ_SEARCH_RESULTS_TXT:SetText(numResults .. " possible matches")
    else
        JJ_SEARCH_RESULTS_TXT:SetText("Showing first 20 of " .. numResults .. " possible matches")
    end
end

--- Get the display name for a location
-- @param poi Location to get display name for
-- @return displayName Display name
local function getLocationDisplayName(poi)
    if poi["AreaName_lang"] == "" then
        return poi["Name_lang"] .. "\n(" .. poi["MapName_lang"] .. ")"
    else
        return poi["Name_lang"] .. "\n(" .. poi["AreaName_lang"] .. ", " .. poi["MapName_lang"] .. ")"
    end
end

--- Modify the location tooltip with info for the given location
-- @param poi       Location to get data from
-- @param button    Button to anchor tooltip to
local function modifyLocationTooltip(poi, button, isDirectionsButton)
    JJ_TOOLTIP:SetOwner(button, "ANCHOR_RIGHT", 0, -JJ_BUTTON_HEIGHT)
    JJ_TOOLTIP:ClearLines()
    if isDirectionsButton then
        JJ_TOOLTIP:AddLine("(EXPERIMENTAL) Get directions to")
        JJ_TOOLTIP:AddLine(poi["Name_lang"])
        JJ_TOOLTIP:AddLine("-")
        JJ_TOOLTIP:AddLine("This feature is experimental and may ")
        JJ_TOOLTIP:AddLine("lead you down dark alleyways and portals ")
        JJ_TOOLTIP:AddLine("you might not have unlocked!")

    else
        JJ_TOOLTIP:AddLine(getLocationDisplayName(poi))
        if poi["Description_lang"] ~= "" then
            JJ_TOOLTIP:AddLine("Description: " .. poi["Description_lang"])
        end
        if poi["Origin"] ~= "" then
            JJ_TOOLTIP:AddLine("Dataset: " .. poi["Origin"])
        end
    end
end

--- Try to find the location of the waypoint at a higher zoom level than the given map
-- @param uiMapId       Map ID of the (possibly) lower zoom level map
-- @param mapPosition   Position of the waypoint on the lower zoom level map
-- @return uiMapId      Map ID of the higher zoom level map if available, otherwise same as input
-- @return x            X coordinate of the waypoint on the higher zoom level map if available, otherwise same as mapPosition.x
-- @return y            Y coordinate of the waypoint on the higher zoom level map if available, otherwise same as mapPosition.y
local function getHigherZoomMapPosition(uiMapId, mapPosition)
    local x = mapPosition.x
    local y = mapPosition.y
    local childMapInfo = C_Map.GetMapInfoAtPosition(uiMapId, mapPosition.x, mapPosition.y)
    local highestZoomReached = (childMapInfo == nil) or (childMapInfo.mapID == uiMapId)
    while not highestZoomReached do
        local left, right, top, bottom = C_Map.GetMapRectOnMap(childMapInfo.mapID, uiMapId)
        x = (mapPosition.x - left) / (right - left)
        y = (mapPosition.y - top) / (bottom - top)
        uiMapId = childMapInfo.mapID

        local nextChildMapInfo = C_Map.GetMapInfoAtPosition(uiMapId, mapPosition.x, mapPosition.y)
        highestZoomReached = (nextChildMapInfo == nil) or (nextChildMapInfo.mapID == uiMapId)
        childMapInfo = nextChildMapInfo
    end
    return uiMapId, x, y
end

--- Sets the data and callbacks for the location button to match the given location
-- @param buttonGroup   Location button group table containing button UI frames
-- @param poi           Location data containing Pos0 (global x), Pos1 (global y), Name_lang (name), and ContinentID
-- @param uiMapId       The uiMapId of where the waypoint should be added
-- @param mapPosition   Vector2D containing the x and y coordinates of the waypoint in the given uiMapId
local function modifyLocationButton(buttonGroup, poi, uiMapId, mapPosition)
    local locationButton = buttonGroup["location"]
    local directionsButton = buttonGroup["directions"]

    locationButton:SetText(getLocationDisplayName(poi))
    local uiMapId, x, y = getHigherZoomMapPosition(uiMapId, mapPosition)

    locationButton:SetScript("OnClick", function(self, button, down)
        TomTom:AddWaypoint(uiMapId, x, y, {
            title = poi["Name_lang"],
            source = "JackJack",
            persistent = true,
            minimap = true,
            world = true,
            crazy = true
        })
        print("Added waypoint for " .. poi["Name_lang"])
    end)

    locationButton:SetScript("OnEnter", function()
        modifyLocationTooltip(poi, locationButton)
        JJ_TOOLTIP:Show()
        local tempWaypointUid = TomTom:AddWaypoint(uiMapId, x, y, {
            title = poi["Name_lang"] .. " (temp)", -- (temp) is to prevent collisions with permanent waypoint, otherwise new waypoint won't be added
            source = "JackJack",
            persistent = false,
            minimap = true,
            world = true,
            crazy = false
        })
        local oldUiMapId = WorldMapFrame:GetMapID()
        WorldMapFrame:SetMapID(uiMapId)

        locationButton:SetScript("OnLeave", function()
            TomTom:RemoveWaypoint(tempWaypointUid)
            JJ_TOOLTIP:Hide()
            WorldMapFrame:SetMapID(oldUiMapId)
        end)
    end)

    directionsButton:SetScript("OnClick", function()
        for _, directionWaypoint in ipairs(JJ_DIRECTIONS_WAYPOINTS) do
            TomTom:RemoveWaypoint(directionWaypoint)
            JJ_DIRECTIONS_WAYPOINTS = {}
        end

        local directions = addon.getDirections(poi["Pos0"], poi["Pos1"], poi["ContinentID"], poi["Name_lang"])
        if directions ~= nil then
            -- directions will arrive inverted, which is good since we want to the first direction to
            -- show up as the crazy arrow by adding it last
            for i, direction in ipairs(directions) do
                -- make it so when we get to the waypoint clear distance, it tries to show the next waypoint
                -- since we're adding more behavior to the default behavior, we have to copy the default callback and run it
                local waypointCallbacks = TomTom:DefaultCallbacks()
                waypointCallbacks["distance"][TomTom.profile.persistence.cleardistance] = function (event, uid, range, distance, lastdistance)
                    local defaultCB = TomTom:DefaultCallbacks()["distance"][TomTom.profile.persistence.cleardistance]
                    defaultCB(event, uid, range, distance, lastdistance)
                    TomTom:SetClosestWaypoint()
                end

                local uiMapId, x, y = getHigherZoomMapPosition(direction["uiMapId"], direction)
                local uid = TomTom:AddWaypoint(uiMapId, x, y, {
                    title = #directions - i + 1 .. " " .. direction["Name_lang"],
                    source = "JackJack (directions)",
                    persistent = true,
                    minimap = true,
                    world = true,
                    crazy = true,
                    callbacks = waypointCallbacks
                })
                table.insert(JJ_DIRECTIONS_WAYPOINTS, uid)
            end
            print("===")
            print("Added direction waypoints to " .. poi["Name_lang"])
            -- when we print directions, we want to read them in normal order, so we reverse the output
            for i = #directions, 1, -1 do
                print(#directions - i + 1, directions[i]["Name_lang"])
            end
        else
            print("No path found to " .. poi["Name_lang"] .. " from your current location! (It might be in an instance, like a dungeon or raid.)")
        end
    end)

    directionsButton:SetScript("OnEnter", function()
        modifyLocationTooltip(poi, directionsButton, true)
        JJ_TOOLTIP:Show()

        directionsButton:SetScript("OnLeave", function()
            JJ_TOOLTIP:Hide()
        end)
    end)
end

--- Adds a new location button to the location button container for the given location
-- @param poi           Location data containing Pos0 (global x), Pos1 (global y), Name_lang (name), and ContinentID
-- @param buttonNumber  Index of the button to add in the location button container
-- @param uiMapId       The uiMapId of where the waypoint should be added
-- @param mapPosition   Vector2D containing the x and y coordinates of the waypoint
-- @return button       UI frame for the location button
local function addLocationButton(poi, buttonNumber, uiMapId, mapPosition)
    local locationbutton = CreateFrame("Button", "JackJackLocationButton" .. buttonNumber, JJ_LOCATION_BUTTON_CONTAINER, "UIPanelButtonTemplate")
    locationbutton:SetSize(JJ_BUTTON_WIDTH, JJ_BUTTON_HEIGHT)
    locationbutton:SetPoint("TOPLEFT", 0, -((buttonNumber - 1) * JJ_BUTTON_HEIGHT))
    
    local directionsbutton = CreateFrame("Button", "JackJackDirectionsButton" .. buttonNumber, JJ_LOCATION_BUTTON_CONTAINER, "UIPanelButtonTemplate")
    directionsbutton:SetSize(JJ_DIRECTIONS_BUTTON_WIDTH, JJ_BUTTON_HEIGHT)
    directionsbutton:SetPoint("TOPLEFT", JJ_BUTTON_WIDTH, -((buttonNumber - 1) * JJ_BUTTON_HEIGHT))
    local directionsTexture = directionsbutton:CreateTexture()
    directionsTexture:SetTexture("Interface\\AddOns\\JackJack\\directions")
    directionsTexture:SetPoint("CENTER")
    directionsTexture:SetSize(JJ_DIRECTIONS_BUTTON_WIDTH / 2, JJ_BUTTON_HEIGHT / 2)
    
    local buttonGroup = {["location"]=locationbutton, ["directions"]=directionsbutton}
    modifyLocationButton(buttonGroup, poi, uiMapId, mapPosition)
    return buttonGroup
end

--- Hides all the location buttons
local function hideLocationButtons()
    for i, buttonGroup in ipairs(JJ_LOCATION_BUTTON_GROUPS) do
        buttonGroup["location"]:Hide()
        buttonGroup["directions"]:Hide()
    end
end

--- Sets the main JJ window to show matches for the given location name
-- @param locationName Search string to match
local function setLocationButtons(locationName)
    -- get all POIs that (fuzzy) match the location name
    local poiMatches = {}
    for rowNumber, poi in pairs(addon.JackJackLocations) do
        if addon.fzy.has_match(locationName, poi["Name_lang"]) then
            -- it's faster to precompute score so table.sort doesn't constantly recompute it in comparisons
            poi["fzyScore"] = addon.fzy.score(locationName, poi["Name_lang"])
            table.insert(poiMatches, poi)
        end
    end
    -- sort by how close the match is to the location name
    table.sort(poiMatches, function(a, b)
        return a["fzyScore"] > b["fzyScore"]
    end)

    -- update UI
    hideLocationButtons()
    setSearchResultsText(#poiMatches)

    local buttonNumber = 1 -- use this instead of iterator because we might skip some buttons for inaccessible locations
    for _, poi in ipairs(poiMatches) do
        if buttonNumber > 20 then break end -- limit to 20 results to prevent lag

        local globalCoords = CreateVector2D(poi["Pos0"], poi["Pos1"])
        local uiMapId, mapPosition = C_Map.GetMapPosFromWorldPos(poi["ContinentID"], globalCoords)
        if mapPosition ~= nil and uiMapId ~= nil then -- don't show any inaccessible/dev locations
            if not JJ_LOCATION_BUTTON_GROUPS[buttonNumber] then
                JJ_LOCATION_BUTTON_GROUPS[buttonNumber] = addLocationButton(poi, buttonNumber, uiMapId, mapPosition)
            else
                local buttongroup = JJ_LOCATION_BUTTON_GROUPS[buttonNumber]
                modifyLocationButton(buttongroup, poi, uiMapId, mapPosition)
                buttongroup["location"]:Show()
                buttongroup["directions"]:Show()
            end
            buttonNumber = buttonNumber + 1
        end
    end
end

--- Sets up the main JackJack window frame
-- @return frame                UI frame for the window
-- @return scrollChild          ScrollChild frame for the location buttons container
-- @return searchBox            EditBox frame for the search box
-- @return searchResultsText    FontString showing number of search resutls
local function setUpFrame()
    local titleFrame, searchBox, searchResultsText = addon.setUpTitleFrame()
    
    local contentFrame = addon.setUpContentFrame(titleFrame)
    contentFrame:Hide()
    
    searchBox:SetScript("OnTextChanged", function(self)
        local query = self:GetText()
        setLocationButtons(query)
        if query == "" or query == nil then
            contentFrame:Hide()
            searchResultsText:SetText('Search for a WoW location (e.g. "Orgrimmar")')
        else
            contentFrame:Show()
        end
    end)

    local frame = contentFrame -- TODO: just replace all the frame references with this one

    -- add a scroll frame which will contain location buttons
    local scrollFrame = CreateFrame("ScrollFrame", "JackJackScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", JJ_MARGIN, -JJ_MARGIN)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -JJ_SCROLLBAR_REGION_WIDTH, JJ_MARGIN)

    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetWidth(1) -- not sure if setting this to 1 has any effect vs setting it to the parent's width
    scrollChild:SetHeight(1) -- this can be any value, it doesn't matter

    return titleFrame, scrollChild, searchBox, searchResultsText
end

--- Sets up the location tooltip frame
local function setUpLocationTooltip()
    local tooltip = CreateFrame("GameTooltip", "JackJackLocationTooltip", UIParent, "GameTooltipTemplate")
    return tooltip
end

JJ_TITLE, JJ_LOCATION_BUTTON_CONTAINER, JJ_SEARCH_BOX, JJ_SEARCH_RESULTS_TXT = setUpFrame()
JJ_LOCATION_BUTTON_GROUPS = {} -- contains {["location"]=Button, ["directions"]=Button} for each button group
JJ_TOOLTIP = setUpLocationTooltip()
JJ_DIRECTIONS_WAYPOINTS = {}

JJ_EVENT_FRAME = CreateFrame("Frame")
JJ_EVENT_FRAME:RegisterEvent("PLAYER_ENTERING_WORLD")
JJ_EVENT_FRAME:SetScript("OnEvent", function (self, event, ...)
    -- show the next directions waypoint when you load into a new zone
    if event == "PLAYER_ENTERING_WORLD" and #JJ_DIRECTIONS_WAYPOINTS > 0 then
        TomTom:SetClosestWaypoint()
    end
end)

SlashCmdList["JACKJACK"] = function(msg, editBox)
    local locationName = msg
    setLocationButtons(locationName)
    JJ_SEARCH_BOX:SetText(locationName)
    JJ_TITLE:Show()
    WorldMapFrame:Show()
end

SlashCmdList["JJRESET"] = function(msg, editBox)
    JJ_TITLE:ClearAllPoints()
    JJ_TITLE:SetPoint("TOPLEFT", WorldMapFrame, "TOPRIGHT", 0, 0)
end