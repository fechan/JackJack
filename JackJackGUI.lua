-- set addon namespace
local addonName, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

local MAIN_FRAME_STYLE = {
    ["WIDTH"] = 350
}

local tabs

function addon:showDirections() tabs:SelectTab("directions") end

local function afterSelectTab(tabs, callbackName, tabName)
    tabs:ReleaseChildren()

    if tabName == "locations" then
        tabs:AddChild(addon:SearchPanel())
    elseif tabName == "directions" then
        tabs:AddChild(addon:DirectionsPanel(addon.AddonState.directions))
    end
end


function addon:initGUI()
    local mainFrame = AceGUI:Create("JJWindow")
    mainFrame.frame:SetParent("WorldMapFrame")
    -- mainFrame.closebutton:Hide() -- HACK: hide Ace3 close button
    mainFrame:SetTitle("JackJack")
    mainFrame:SetPoint("TOPLEFT", "WorldMapFrame", "TOPRIGHT")
    mainFrame:SetWidth(MAIN_FRAME_STYLE.WIDTH)
    mainFrame:SetHeight(165)
    mainFrame:SetLayout("Flow")
    
    -- tabs
    tabs = AceGUI:Create("TabGroup")
    tabs:SetTabs({
        {value = "locations", text = "Locations"},
        {value = "directions", text = "Directions"}
    })
    tabs:SetCallback("OnGroupSelected", afterSelectTab)
    tabs:SelectTab("locations")
    tabs:SetFullHeight(true)
    tabs:SetFullWidth(true)
    tabs:SetLayout("Flow")
    
    -- add all the elements
    mainFrame:AddChild(tabs)
end