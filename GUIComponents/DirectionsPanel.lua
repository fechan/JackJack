local addonName, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

local STYLE = {
    -- see https://github.com/Gethe/wow-ui-source/blob/live/Interface/SharedXML/SharedFontStyles.xml
    ["EXPLANATION_FONT"] = "GameFontNormalMed2"
}

local function applyFont(fontName, widget)
    local font = CreateFont("JJTempFont")
    font:SetFontObject(fontName)
    widget:SetFontObject(font)
end

local function ExplanationText()
    local explanationText = AceGUI:Create("Label")
    explanationText:SetText(
        "Search for places in the Locations tab " ..
        "and click one of the Directions buttons on the " ..
        "right." ..
        "\n\n" ..
        "Directions to that place will appear here!"
    )

    applyFont(STYLE.EXPLANATION_FONT, explanationText)
    explanationText:SetFullWidth(true)

    return explanationText
end

local function processDirectionsList(directions, locationListContainerContainer)
    locationListContainerContainer:ReleaseChildren()
    local locationList, locationListContainer = addon.ScrollingList()

    addon:clearDirectionWaypoints()

    for i, direction in ipairs(directions) do
        local direction = directions[i]
        local locationButton = addon:LocationButton(direction)
        locationList:AddChild(locationButton)

        addon:createDirectionWaypointFor(direction)

        -- print(direction.directionNbr, direction.Name_lang)
    end
    TomTom:SetClosestWaypoint()

    locationListContainerContainer:AddChild(locationListContainer)
end

function addon:DirectionsPanel(directions)
    if directions == nil then return ExplanationText() end

    local directionsPanel = AceGUI:Create("SimpleGroup")
    directionsPanel:SetFullHeight(true)
    directionsPanel:SetFullWidth(true)
    directionsPanel:SetLayout("Flow")
    
    -- header that says "Directions to [location]"
    local header = AceGUI:Create("Label")
    if #directions == 0 then
        header:SetText("Couldn't find a path to " .. directions[1].Name_lang .. " from your location!" ..
                        "\n\n" ..
                        "It might be inside a dungeon or raid you're not currently in!")
    else
        header:SetText("Directions to " .. directions[1].Name_lang .. "\n")
    end
    applyFont(STYLE.EXPLANATION_FONT, header)
    header:SetFullWidth(true)
    directionsPanel:AddChild(header)

    -- container for the locationListContainer
    -- This is needed because locationListContainer doesn't fill
    -- available height unless it's inside a container with the
    -- "Fill" layout, even though SetFullHeight is set.
    -- This also allows us to call ReleaseChildren on it to
    -- delete the locationListContainer + locationList, since
    -- we can't Release it directly without it breaking ReleaseChildren
    -- for any parent elements.
    local locationListContainerContainer = AceGUI:Create("SimpleGroup")
    locationListContainerContainer:SetFullHeight(true)
    locationListContainerContainer:SetFullWidth(true)
    locationListContainerContainer:SetLayout("Fill")
    directionsPanel:AddChild(locationListContainerContainer)

    processDirectionsList(directions, locationListContainerContainer)

    return directionsPanel
end