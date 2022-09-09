-- set addon namespace
local addonName, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

local MAIN_FRAME_STYLE = {
    ["WIDTH"] = 350
}

local function selectTab(tabs, callbackName, tabName)
    tabs:ReleaseChildren()
    if tabName == "locations" then
        tabs:AddChild(addon:SearchPanel())
    elseif tabName == "directions" then
        -- TODO: implement me
    end
end

function addon:initGUI()
    local mainFrame = AceGUI:Create("Window")
    mainFrame.frame:SetParent("WorldMapFrame")
    mainFrame.closebutton:Hide() -- HACK: hide Ace3 close button
    mainFrame:SetTitle("JackJack")
    mainFrame:SetPoint("TOPLEFT", "WorldMapFrame", "TOPRIGHT")
    mainFrame:SetWidth(MAIN_FRAME_STYLE.WIDTH)
    mainFrame:SetLayout("Flow")
    
    local tabs = AceGUI:Create("TabGroup")
    tabs:SetTabs({
        {value = "locations", text = "Locations"},
        {value = "directions", text = "Directions"}
    })
    tabs:SetCallback("OnGroupSelected", selectTab)
    tabs:SelectTab("locations")
    tabs:SetFullHeight(true)
    tabs:SetFullWidth(true)
    tabs:SetLayout("Flow")
    
    -- add all the elements
    mainFrame:AddChild(tabs)
end