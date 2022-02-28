-- set addon namespace
local addonName, addon = ...

-- slash commands
SLASH_JACKJACK1 = "/jackjack"
SLASH_JACKJACK2 = "/jj"

-- sizing for frames
JJ_WIDTH = 400
JJ_HEIGHT = 400
JJ_MARGIN = 8
JJ_SCROLLBAR_REGION_WIDTH = 30 -- not the actual width of the scrollbar, just the region the scrollbar is in
JJ_BUTTON_WIDTH = JJ_WIDTH - JJ_SCROLLBAR_REGION_WIDTH - JJ_MARGIN
JJ_BUTTON_HEIGHT = 40
JJ_CLOSE_BUTTON_HEIGHT = 40

--- Sets up the main JackJack window frame
-- @return frame        UI frame for the window
-- @return scrollChild  UI frame for the location buttons container
local function setUpFrame()
    -- create the window
    local frame = CreateFrame("Frame", "JackJackFrame", UIParent, "BackdropTemplate")
    frame:SetSize(JJ_WIDTH, JJ_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
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

    -- add a scroll frame which will contain location buttons
    local scrollFrame = CreateFrame("ScrollFrame", "JackJackScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", JJ_MARGIN, -JJ_MARGIN)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -JJ_SCROLLBAR_REGION_WIDTH, JJ_MARGIN * 2 + JJ_CLOSE_BUTTON_HEIGHT)

    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetWidth(1) -- not sure if setting this to 1 has any effect vs setting it to the parent's width
    scrollChild:SetHeight(1) -- this can be any value, it doesn't matter

    -- add big close button on bottom
    local closeButton = CreateFrame("Button", "JackJackCloseButton", frame, "UIPanelButtonTemplate")
    closeButton:SetSize(JJ_WIDTH - JJ_MARGIN, JJ_CLOSE_BUTTON_HEIGHT)
    closeButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, JJ_MARGIN)
    closeButton:SetText("Cancel")
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    return frame, scrollChild
end

--- Sets up the location tooltip frame
local function setUpLocationTooltip()
    local tooltip = CreateFrame("GameTooltip", "JackJackLocationTooltip", UIParent, "GameTooltipTemplate")
    return tooltip
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
-- @param poi Location to get data from
local function modifyLocationTooltip(poi)
    JJ_TOOLTIP:SetOwner(UIParent, "ANCHOR_CURSOR", 0, 0)
    JJ_TOOLTIP:ClearLines()
    JJ_TOOLTIP:AddLine(getLocationDisplayName(poi))
    if poi["Description_lang"] ~= "" then
        JJ_TOOLTIP:AddLine("Description: " .. poi["Description_lang"])
    end
end

--- Sets the data and callbacks for the location button to match the given location
-- @param button    UI frame for the location button
-- @param location  Location data containing Pos0 (global x), Pos1 (global y), Name_lang (name), and ContinentID
local function modifyLocationButton(button, poi)
    button:SetText(getLocationDisplayName(poi))
    button:SetScript("OnClick", function()
        local global_coords = CreateVector2D(poi["Pos0"], poi["Pos1"])
        local uiMapId, mapPosition = C_Map.GetMapPosFromWorldPos(poi["ContinentID"], global_coords)
        TomTom:AddWaypoint(uiMapId, mapPosition.x, mapPosition.y, {
            title = poi["Name_lang"],
            source = "JackJack",
            persistent = true,
            minimap = true,
            world = true,
            crazy = true
        })
        JJ_WINDOW:Hide()
        print("Added waypoint for " .. poi["Name_lang"])
    end)

    button:SetScript("OnEnter", function()
        modifyLocationTooltip(poi)
        JJ_TOOLTIP:Show()
    end)

    button:SetScript("OnLeave", function()
        JJ_TOOLTIP:Hide()
    end)
end

--- Adds a new location button to the location button container for the given location
-- @param poi           Location data containing Pos0 (global x), Pos1 (global y), Name_lang (name), and ContinentID
-- @param buttonNumber  Index of the button to add in the location button container
-- @return button       UI frame for the location button
local function addLocationButton(poi, buttonNumber)
    local button = CreateFrame("Button", "JackJackLocationButton" .. buttonNumber, JJ_LOCATION_BUTTON_CONTAINER, "UIPanelButtonTemplate")
    button:SetSize(JJ_BUTTON_WIDTH, JJ_BUTTON_HEIGHT)
    button:SetPoint("TOPLEFT", 0, -((buttonNumber - 1) * JJ_BUTTON_HEIGHT))
    modifyLocationButton(button, poi)

    return button
end

--- Hides all the location buttons
local function hideLocationButtons()
    for i, button in ipairs(JJ_LOCATION_BUTTONS) do
        button:Hide()
    end
end

JJ_WINDOW, JJ_LOCATION_BUTTON_CONTAINER = setUpFrame()
JJ_LOCATION_BUTTONS = {}
JJ_TOOLTIP = setUpLocationTooltip()

SlashCmdList["JACKJACK"] = function(msg, editBox)
    local locationName = msg

    -- get all POIs that (fuzzy) match the location name
    local poiMatches = {}
    for rowNumber, poi in pairs(addon.locations) do
        if addon.fzy.has_match(locationName, poi["Name_lang"]) then
            table.insert(poiMatches, poi)
        end
    end
    -- sort by how close the match is to the location name
    table.sort(poiMatches, function(a, b)
        return addon.fzy.score(locationName, a["Name_lang"]) > addon.fzy.score(locationName, b["Name_lang"])
    end)

    -- update UI
    if #poiMatches ~= 0 then
        hideLocationButtons()
        for buttonNumber, poi in ipairs(poiMatches) do
            if not JJ_LOCATION_BUTTONS[buttonNumber] then
                JJ_LOCATION_BUTTONS[buttonNumber] = addLocationButton(poi, buttonNumber)
            else
                local button = JJ_LOCATION_BUTTONS[buttonNumber]
                modifyLocationButton(button, poi)
                button:Show()
            end
        end
        JJ_WINDOW:Show()
    else
        print("No locations found for " .. locationName)
    end
end