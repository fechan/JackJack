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
        if (addon.Settings.profile.showTaxiDirections or
                direction.Transport:find("^taxinode") == nil) then
            local locationButton = addon:LocationButton(direction)
            locationList:AddChild(locationButton)
        end
    end
    
    for i=#directions,1,-1 do
        local direction = directions[i]
        if (addon.Settings.profile.showTaxiDirections or
                direction.Transport:find("^taxinode") == nil) then
            addon:createDirectionWaypointFor(direction)
        end
    end
    TomTom:SetClosestWaypoint()

    locationListContainerContainer:AddChild(locationListContainer)
end

local function clearDirections()
    addon.AddonState.directions = nil
    addon:clearDirectionWaypoints()
    addon:showDirections()
end

function addon:DirectionsPanel(directions)
    if directions == nil then return ExplanationText() end

    local directionsPanel = AceGUI:Create("SimpleGroup")
    directionsPanel:SetFullHeight(true)
    directionsPanel:SetFullWidth(true)
    directionsPanel:SetLayout("Flow")

    -- header that says "Directions to [location]"
    if directions["ErrorGettingTo"] then
        local header = AceGUI:Create("Label")
        header:SetText("Couldn't find a path to " .. directions["ErrorGettingTo"].Name_lang .. " from your location!" ..
                        "\n\n" ..
                        "It might be inside a dungeon or raid you're not currently in!")
        applyFont(STYLE.EXPLANATION_FONT, header)
        header:SetFullWidth(true)
        directionsPanel:AddChild(header)
    else
        local header = AceGUI:Create("Heading")
        header:SetText("Directions to " .. directions[#directions].Name_lang .. "\n")
        header:SetRelativeWidth(1)
        directionsPanel:AddChild(header)

        -- button that lets you clear directions
        local clearDirectionsButton = AceGUI:Create("Button")
        clearDirectionsButton:SetText("Clear")
        clearDirectionsButton:SetWidth(80)
        clearDirectionsButton:SetCallback("OnClick", clearDirections)
        directionsPanel:AddChild(clearDirectionsButton)

        -- checkbox for showing taxi directions in the directions list
        local showTaxiCheckbox = AceGUI:Create("CheckBox")
        showTaxiCheckbox:SetLabel("Show flight masters")
        showTaxiCheckbox:SetCallback("OnValueChanged", function (checkbox, callbackName, value)
            addon.Settings.profile.showTaxiDirections = value
            addon:showDirections()
        end)
        showTaxiCheckbox:SetValue(addon.Settings.profile.showTaxiDirections)
        directionsPanel:AddChild(showTaxiCheckbox)
    end

    if directions["ErrorGettingTo"] == nil then
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
    end

    return directionsPanel
end