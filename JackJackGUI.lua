-- set addon namespace
local addonName, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

local MAIN_FRAME_STYLE = {
    ["WIDTH"] = 350
}

local mainFrame, locationList

local function populateLocationList(searchBox, callbackName, query)
    locationList:ReleaseChildren()
    for idx, location in ipairs(addon:locationsMatching(query, 20)) do
        local button = addon:LocationButton(location)
        locationList:AddChild(button)
    end
end

function addon:initGUI()
    mainFrame = AceGUI:Create("Window")
    mainFrame.frame:SetParent("WorldMapFrame")
    mainFrame.closebutton:Hide() -- HACK: hide Ace3 close button
    mainFrame:SetTitle("JackJack")
    mainFrame:SetPoint("TOPLEFT", "WorldMapFrame", "TOPRIGHT")
    mainFrame:SetWidth(MAIN_FRAME_STYLE.WIDTH)
    mainFrame:SetLayout("Flow")

    -- search box
    local searchBox = AceGUI:Create("EditBox")
    searchBox:SetCallback("OnTextChanged", populateLocationList)
    searchBox:SetFullWidth(true)
    searchBox:DisableButton(true)
    
    -- location list and its parent scrolling container
    local scrollContainer = AceGUI:Create("SimpleGroup")
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetFullHeight(true)
    scrollContainer:SetLayout("Fill")
    -- scrollContainer:SetPoint("BOTTOMRIGHT", mainFrame.frame, "BOTTOMRIGHT")
    
    locationList = AceGUI:Create("ScrollFrame")
    locationList:SetLayout("List")
    scrollContainer:AddChild(locationList)
    
    -- add all the elements
    mainFrame:AddChild(searchBox)
    mainFrame:AddChild(scrollContainer)
end