-- lib imports
local hbd = LibStub("HereBeDragons-2.0")

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
JJ_BUTTON_HEIGHT = 20


SlashCmdList["JACKJACK"] = function(msg, editBox)
    local locationName = msg

    local frame = CreateFrame("Frame", "JackJackFrame", UIParent, "BackdropTemplate")
    frame:SetSize(JJ_WIDTH, JJ_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(1)

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

    -- add a scroll frame to the frame with scroll bar and scroll child
    local scrollFrame = CreateFrame("ScrollFrame", "JackJackScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", JJ_MARGIN, -JJ_MARGIN)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -JJ_SCROLLBAR_REGION_WIDTH, JJ_MARGIN)

    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetWidth(1) -- not sure if setting this to 1 has any effect vs setting it to the parent's width
    scrollChild:SetHeight(1) -- this can be any value, it doesn't matter

    local buttonNumber = 0 -- track how many buttons we've created. Each location gets a button.
    for rowNumber, poi in pairs(addon.areapoi) do
        if poi["Name_lang"]:lower():find(locationName:lower()) then
            print("Found match for " .. poi["Name_lang"])
            local button = CreateFrame("Button", "JackJackButton" .. buttonNumber, scrollChild, "UIPanelButtonTemplate")
            button:SetSize(JJ_BUTTON_WIDTH, 20)
            button:SetPoint("TOPLEFT", 0, -(buttonNumber * 20))
            buttonNumber = buttonNumber + 1
            button:SetText(poi["Name_lang"])
            button:SetScript("OnClick", function()
                local global_coords = CreateVector2D(poi["Pos0"], poi["Pos1"])
                local uiMapId, mapPosition = C_Map.GetMapPosFromWorldPos(poi["ContinentID"], global_coords)
                local waypointUid = TomTom:AddWaypoint(uiMapId, mapPosition.x, mapPosition.y, {
                    title = poi["Name_lang"],
                    source = "JackJack",
                    persistent = true,
                    minimap = true,
                    world = true,
                    crazy = true
                })
                print("Added waypoint for " .. poi["Name_lang"])
            end)
        end
    end
end