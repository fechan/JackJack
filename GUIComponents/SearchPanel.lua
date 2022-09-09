--- SearchPanel.lua: The panel for the location list with the search box above it
--- There should only ever be one of these at a time, so it's fine to keep state
--- as local variables here

local addonName, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

local searchPanel
local locationList, locationListContainer

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
    for idx, location in ipairs(addon:locationsMatching(query, 20)) do
        local button = addon:LocationButton(location)
        locationList:AddChild(button)
    end

    locationListContainerContainer:AddChild(locationListContainer)
end

function addon:SearchPanel()
    searchPanel = AceGUI:Create("SimpleGroup")
    searchPanel:SetFullHeight(true)
    searchPanel:SetFullWidth(true)
    searchPanel:SetLayout("Flow")

    -- search box
    local searchBox = AceGUI:Create("EditBox")
    searchBox:SetCallback("OnTextChanged", populateLocationList)
    searchBox:SetFullWidth(true)
    searchBox:DisableButton(true)
    searchPanel:AddChild(searchBox)

    -- continer for the locationListContainer (see comment at variable declaration)
    locationListContainerContainer = AceGUI:Create("SimpleGroup")
    locationListContainerContainer:SetFullHeight(true)
    locationListContainerContainer:SetFullWidth(true)
    locationListContainerContainer:SetLayout("Fill")
    searchPanel:AddChild(locationListContainerContainer)

    return searchPanel
end