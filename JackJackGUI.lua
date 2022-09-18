-- set addon namespace
local addonName, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

local MAIN_FRAME_STYLE = {
    ["WIDTH"] = 350
}

local tabs, minimizeFunc

function addon:showDirections() tabs:SelectTab("directions") end

local function afterSelectTab(tabs, callbackName, tabName)
    tabs:ReleaseChildren()

    minimizeFunc = function (minimized) end -- dummy function that does nothing in case tab panel doesn't minimize
    if tabName == "locations" then
        local searchPanel, minimizeSearchPanel = addon:SearchPanel()
        tabs:AddChild(searchPanel)
        minimizeFunc = minimizeSearchPanel
    elseif tabName == "directions" then
        tabs:AddChild(addon:DirectionsPanel(addon.AddonState.directions))
    end
end


function addon:initGUI()
    local mainFrame = AceGUI:Create("JJWindow")
    mainFrame.frame:SetParent("WorldMapFrame")
    mainFrame:SetTitle("JackJack")
    mainFrame:SetPoint("TOPLEFT", "WorldMapFrame", "TOPRIGHT")
    mainFrame:SetWidth(MAIN_FRAME_STYLE.WIDTH)
    mainFrame:SetHeight(165)
    mainFrame:SetLayout("Flow")
    mainFrame:SetCallback("OnMinimizeClicked", function(_, _, minimize) minimizeFunc(minimize) end)
    
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