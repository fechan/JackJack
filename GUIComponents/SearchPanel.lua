--- SearchPanel.lua: The panel for the location list with the search box above it
--- There should only ever be one of these at a time, so it's fine to keep state
--- as local variables here

local addonName, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

local locationList, locationListContainer
local resultsText

--- Get the text that displays the number of search results accordingly
-- @param numResults    The number of search results
-- @param queryIsBlank  Whether the searqh query is blank
local function getSearchResultsText(numResults, queryIsBlank)
    if queryIsBlank then
        return "Find locations by name in the search box above"
    elseif numResults == 0 then
        return "No possible matching locations found!"
    elseif numResults < 20 then
        return numResults .. " possible matches"
    else
        return "Showing first 20 of " .. numResults .. " possible matches"
    end
end

-- This is needed because locationListContainer doesn't fill
-- available height unless it's inside a container with the
-- "Fill" layout, even though SetFullHeight is set.
-- This also allows us to call ReleaseChildren on it to
-- delete the locationListContainer + locationList, since
-- we can't Release it directly without it breaking ReleaseChildren
-- for any parent elements.
local locationListContainerContainer

local function populateLocationList(searchBox, callbackName, query)
    -- delete and create new location list
    locationListContainerContainer:ReleaseChildren()
    locationList, locationListContainer = addon.ScrollingList()

    -- put buttons in the location list
    local locations = addon:locationsMatching(query, 20)
    for idx, location in ipairs(locations) do
        local button = addon:LocationButton(location)
        locationList:AddChild(button)
    end

    resultsText:SetText(getSearchResultsText(#locations, query == ""))

    locationListContainerContainer:AddChild(locationListContainer)
end

function addon:SearchPanel()
    local searchPanel = AceGUI:Create("SimpleGroup")
    searchPanel:SetFullHeight(true)
    searchPanel:SetFullWidth(true)
    searchPanel:SetLayout("Flow")

    -- search box
    local searchBox = AceGUI:Create("EditBox")
    searchBox:SetCallback("OnTextChanged", populateLocationList)
    searchBox:SetFullWidth(true)
    searchBox:DisableButton(true)
    searchPanel:AddChild(searchBox)

    -- search result meta text
    resultsText = AceGUI:Create("Label")
    resultsText:SetFullWidth(true)
    searchPanel:AddChild(resultsText)

    -- container for the locationListContainer (see comment at variable declaration)
    locationListContainerContainer = AceGUI:Create("SimpleGroup")
    locationListContainerContainer:SetFullHeight(true)
    locationListContainerContainer:SetFullWidth(true)
    locationListContainerContainer:SetLayout("Fill")
    searchPanel:AddChild(locationListContainerContainer)

    -- pre-populate the location list
    populateLocationList(searchBox, nil, "")

    return searchPanel
end