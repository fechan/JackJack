local addonName, addon = ...

addon.UI_CONSTS = {
    ["WIDTH"] = 350,
    ["TITLE_FRAME_HEIGHT"] = 100,
    ["CONTENT_HEIGHT"] = 500,
    ["MARGIN"] = 8,
    ["SCROLLBAR_REGION_WIDTH"] = 30, -- not the actual width of the scrollbar, just the region the scrollbar is in
    ["DIRECTIONS_BUTTON_WIDTH"] = 40,
    ["BUTTON_HEIGHT"] = 40,
    ["SEARCH_HEIGHT"] = 25,
    ["TITLEBAR_HEIGHT"] = 64,
}
addon.UI_CONSTS["BUTTON_WIDTH"] = addon.UI_CONSTS.WIDTH -
    addon.UI_CONSTS.SCROLLBAR_REGION_WIDTH -
    addon.UI_CONSTS.MARGIN -
    addon.UI_CONSTS.DIRECTIONS_BUTTON_WIDTH
addon.UI_CONSTS["SEARCH_WIDTH"] = addon.UI_CONSTS.WIDTH - (3 * addon.UI_CONSTS.MARGIN)

--- Sets up the title frame that's always visible when the map is open
-- @return frame            UI frame for the title
-- @return searchBox        UI frame for the search box in the title frame
addon.setUpTitleFrame = function ()
    local frame = CreateFrame("Frame", "JackJackTitle", WorldMapFrame, "BackdropTemplate")
    frame:SetSize(addon.UI_CONSTS.WIDTH, addon.UI_CONSTS.TITLE_FRAME_HEIGHT)
    if not frame:IsUserPlaced() then
        frame:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 0, 0)
    end
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(1)
    --frame:Hide() -- TODO: do we need this or not

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileEdge = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })

    -- make it movable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- add title bar (the very top, and actually contains the title string)
    local titleBar = frame:CreateTexture(nil, "ARTWORK")
    titleBar:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    titleBar:SetPoint("CENTER", frame, "TOP", 0, -addon.UI_CONSTS.TITLEBAR_HEIGHT / 4)
    titleBar:SetSize(256, addon.UI_CONSTS.TITLEBAR_HEIGHT)

    -- add text to title bar
    local titleText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    titleText:SetPoint("CENTER", frame, "TOP", 0, -4)
    titleText:SetText("JackJack")

    -- extend drag area to include title bar
    frame:SetHitRectInsets(0, 0, -addon.UI_CONSTS.TITLEBAR_HEIGHT / 2, 0)

    -- add a search box
    local searchBox = CreateFrame("EditBox", "JackJackSearchBox", frame, "InputBoxTemplate")
    searchBox:SetFontObject("GameFontNormalLarge")
    searchBox:SetSize(addon.UI_CONSTS.SEARCH_WIDTH, addon.UI_CONSTS.SEARCH_HEIGHT)
    searchBox:SetPoint("TOP", frame, "TOP", 0, (-addon.UI_CONSTS.TITLEBAR_HEIGHT / 4) - addon.UI_CONSTS.MARGIN)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", onSearchCallback)

    return frame, searchBox
end

--- Set up the content frame that's only visible when there's a search
-- @param uiParent  The parent frame for the content frame
addon.setUpContentFrame = function(uiParent)
    local frame = CreateFrame("Frame", "JackJackContents", uiParent, "BackdropTemplate")
    frame:SetSize(addon.UI_CONSTS.WIDTH, addon.UI_CONSTS.CONTENT_HEIGHT)
    frame:SetPoint("TOPLEFT", uiParent, "BOTTOMLEFT", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(1)

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileEdge = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })

    return frame
end