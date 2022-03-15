-- set addon namespace
local addonName, addon = ...

-- slash commands
SLASH_JACKJACK1 = "/jackjack"
SLASH_JACKJACK2 = "/jj"

-- sizing for frames
JJ_WIDTH = 350
JJ_HEIGHT = 500
JJ_MARGIN = 8
JJ_SCROLLBAR_REGION_WIDTH = 30 -- not the actual width of the scrollbar, just the region the scrollbar is in
JJ_BUTTON_WIDTH = JJ_WIDTH - JJ_SCROLLBAR_REGION_WIDTH - JJ_MARGIN
JJ_BUTTON_HEIGHT = 40
JJ_SEARCH_HEIGHT = 25
JJ_SEARCH_WIDTH = JJ_WIDTH - (3 * JJ_MARGIN)
JJ_TITLEBAR_HEIGHT = 64

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
local function modifyLocationTooltip(poi, button)
    JJ_TOOLTIP:SetOwner(button, "ANCHOR_RIGHT", 0, -JJ_BUTTON_HEIGHT)
    JJ_TOOLTIP:ClearLines()
    JJ_TOOLTIP:AddLine(getLocationDisplayName(poi))
    if poi["Description_lang"] ~= "" then
        JJ_TOOLTIP:AddLine("Description: " .. poi["Description_lang"])
    end
    if poi["Origin"] ~= "" then
        JJ_TOOLTIP:AddLine("Dataset: " .. poi["Origin"])
    end
end

--- Sets the data and callbacks for the location button to match the given location
-- @param button        UI frame for the location button
-- @param location      Location data containing Pos0 (global x), Pos1 (global y), Name_lang (name), and ContinentID
-- @param uiMapId       The uiMapId of where the waypoint should be added
-- @param mapPosition   Vector2D containing the x and y coordinates of the waypoint
local function modifyLocationButton(button, poi, uiMapId, mapPosition)
    button:SetText(getLocationDisplayName(poi))
    button:SetScript("OnClick", function()
        TomTom:AddWaypoint(uiMapId, mapPosition.x, mapPosition.y, {
            title = poi["Name_lang"],
            source = "JackJack",
            persistent = true,
            minimap = true,
            world = true,
            crazy = true
        })
        --JJ_WINDOW:Hide() -- TODO: replace this with the search results hiding instead
        print("Added waypoint for " .. poi["Name_lang"])
    end)

    button:SetScript("OnEnter", function()
        modifyLocationTooltip(poi, button)
        JJ_TOOLTIP:Show()
        local tempWaypointUid = TomTom:AddWaypoint(uiMapId, mapPosition.x, mapPosition.y, {
            title = poi["Name_lang"] .. " (temp)", -- (temp) is to prevent collisions with permanent waypoint, otherwise new waypoint won't be added
            source = "JackJack",
            persistent = false,
            minimap = true,
            world = true,
            crazy = false
        })
        local oldUiMapId = WorldMapFrame:GetMapID()
        WorldMapFrame:SetMapID(uiMapId)

        button:SetScript("OnLeave", function()
            TomTom:RemoveWaypoint(tempWaypointUid)
            JJ_TOOLTIP:Hide()
            WorldMapFrame:SetMapID(oldUiMapId)
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
    local button = CreateFrame("Button", "JackJackLocationButton" .. buttonNumber, JJ_LOCATION_BUTTON_CONTAINER, "UIPanelButtonTemplate")
    button:SetSize(JJ_BUTTON_WIDTH, JJ_BUTTON_HEIGHT)
    button:SetPoint("TOPLEFT", 0, -((buttonNumber - 1) * JJ_BUTTON_HEIGHT))
    modifyLocationButton(button, poi, uiMapId, mapPosition)

    return button
end

--- Hides all the location buttons
local function hideLocationButtons()
    for i, button in ipairs(JJ_LOCATION_BUTTONS) do
        button:Hide()
    end
end

--- Sets the main JJ window to show matches for the given location name
-- @param locationName Search string to match
local function setLocationButtons(locationName)
    -- get all POIs that (fuzzy) match the location name
    local poiMatches = {}
    for rowNumber, poi in pairs(addon.locations) do
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

        local global_coords = CreateVector2D(poi["Pos0"], poi["Pos1"])
        local uiMapId, mapPosition = C_Map.GetMapPosFromWorldPos(poi["ContinentID"], global_coords)
        if mapPosition ~= nil and uiMapId ~= nil then -- don't show any inaccessible/dev locations
            if not JJ_LOCATION_BUTTONS[buttonNumber] then
                JJ_LOCATION_BUTTONS[buttonNumber] = addLocationButton(poi, buttonNumber, uiMapId, mapPosition)
            else
                local button = JJ_LOCATION_BUTTONS[buttonNumber]
                modifyLocationButton(button, poi, uiMapId, mapPosition)
                button:Show()
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
    -- create the window
    local frame = CreateFrame("Frame", "JackJackFrame", WorldMapFrame, "BackdropTemplate")
    frame:SetSize(JJ_WIDTH, JJ_HEIGHT)
    if not frame:IsUserPlaced() then
        frame:SetPoint("TOPLEFT", WorldMapFrame, "TOPRIGHT", 0, 0)
    end
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(1)
    frame:Hide()

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileEdge = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })

    -- make it movable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- add title bar
    local titleBar = frame:CreateTexture(nil, "ARTWORK")
    titleBar:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    titleBar:SetPoint("CENTER", frame, "TOP", 0, -JJ_TITLEBAR_HEIGHT / 4)
    titleBar:SetSize(256, JJ_TITLEBAR_HEIGHT)

    -- add text to title bar
    local titleText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    titleText:SetPoint("CENTER", frame, "TOP", 0, -4)
    titleText:SetText("JackJack")

    -- extend drag area to include title bar
    frame:SetHitRectInsets(0, 0, -JJ_TITLEBAR_HEIGHT / 2, 0)

    -- add a search box
    local searchBox = CreateFrame("EditBox", "JackJackSearchBox", frame, "InputBoxTemplate")
    searchBox:SetFontObject("GameFontNormalLarge")
    searchBox:SetSize(JJ_SEARCH_WIDTH, JJ_SEARCH_HEIGHT)
    searchBox:SetPoint("TOP", frame, "TOP", 0, (-JJ_TITLEBAR_HEIGHT / 4) - JJ_MARGIN)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", function(self)
        setLocationButtons(self:GetText())
    end)

    -- add text below search box that shows the number of locations found
    local searchResultsText = searchBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchResultsText:SetPoint("BOTTOMLEFT", searchBox, "BOTTOMLEFT", 0, -2 * JJ_MARGIN)
    searchResultsText:SetText("No possible matching locations found!")

    -- add a scroll frame which will contain location buttons
    local scrollFrame = CreateFrame("ScrollFrame", "JackJackScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", JJ_MARGIN, -6 * JJ_MARGIN - JJ_SEARCH_HEIGHT)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -JJ_SCROLLBAR_REGION_WIDTH, JJ_MARGIN)

    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetWidth(1) -- not sure if setting this to 1 has any effect vs setting it to the parent's width
    scrollChild:SetHeight(1) -- this can be any value, it doesn't matter

    frame:Show()
    return frame, scrollChild, searchBox, searchResultsText
end

--- Sets up the location tooltip frame
local function setUpLocationTooltip()
    local tooltip = CreateFrame("GameTooltip", "JackJackLocationTooltip", UIParent, "GameTooltipTemplate")
    return tooltip
end

JJ_WINDOW, JJ_LOCATION_BUTTON_CONTAINER, JJ_SEARCH_BOX, JJ_SEARCH_RESULTS_TXT = setUpFrame()
JJ_LOCATION_BUTTONS = {}
JJ_TOOLTIP = setUpLocationTooltip()

SlashCmdList["JACKJACK"] = function(msg, editBox)
    local locationName = msg
    setLocationButtons(locationName)
    JJ_SEARCH_BOX:SetText(locationName)
    JJ_WINDOW:Show()
    WorldMapFrame:Show()
end