local addonName, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

local STYLE = {
    -- see https://github.com/Gethe/wow-ui-source/blob/live/Interface/SharedXML/SharedFontStyles.xml
    ["EXPLANATION_FONT"] = "GameFontNormalMed2"
}

local function populateDirectionsList(directions, locationListContainerContainer)
    for i = #directions, 1, -1 do
        print(#directions - i + 1, directions[i]["Name_lang"])
    end

    -- delete and create new location list
    locationListContainerContainer:ReleaseChildren()
    local locationList, locationListContainer = addon.ScrollingList()

    -- put buttons in the location list
    for i = #directions, 1, -1 do
        local locationButton = addon:LocationButton(directions[i])
        locationList:AddChild(locationButton)
    end

    locationListContainerContainer:AddChild(locationListContainer)
end

function addon:DirectionsPanel(directions)
    if directions == nil then
        local explanationText = AceGUI:Create("Label")
        explanationText:SetText(
            "Search for places in the Locations tab " ..
            "and click one of the Directions buttons on the " ..
            "right." ..
            "\n\n" ..
            "Directions to that place will appear here!"
        )

        local font = CreateFont("JJDirectionsExplanationFont")
        font:SetFontObject(STYLE.EXPLANATION_FONT)
        explanationText:SetFontObject(font)

        explanationText:SetFullWidth(true)

        return explanationText
    end

    local directionsPanel = AceGUI:Create("SimpleGroup")
    directionsPanel:SetFullHeight(true)
    directionsPanel:SetFullWidth(true)
    directionsPanel:SetLayout("Flow")

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

    populateDirectionsList(directions, locationListContainerContainer)

    return directionsPanel
end