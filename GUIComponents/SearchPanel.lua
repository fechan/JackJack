local addonName, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

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

--- Ace callback handler that populates the location list when text is typed into the search box
-- @param searchBox     Searchbox widget
-- @param callbackName  Name of the callback event (should always be "OnTextChanged")
-- @param querying      Search query
local function populateLocationList(searchBox, callbackName, query)
    -- delete and create new location list
    local locationListContainerContainer = searchBox:GetUserData("locationListContainerContainer")
    locationListContainerContainer:ReleaseChildren()
    local locationList, locationListContainer = addon.ScrollingList()

    -- put buttons in the location list
    local locations = addon:locationsMatching(query, 20)
    for idx, location in ipairs(locations) do
        local button = addon:LocationButton(location)
        locationList:AddChild(button)
    end

    local resultsText = searchBox:GetUserData("resultsText")
    resultsText:SetText(getSearchResultsText(#locations, query == ""))

    locationListContainerContainer:AddChild(locationListContainer)
end

--- Factory method returning the panel for the location list with the search box above it
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
    searchBox:SetUserData("resultsText", resultsText)

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
    searchPanel:AddChild(locationListContainerContainer)
    searchBox:SetUserData("locationListContainerContainer", locationListContainerContainer)

    -- pre-populate the location list
    populateLocationList(searchBox, nil, "")

    return searchPanel
end