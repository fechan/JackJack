-- set addon namespace
local addonName, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

local MAIN_FRAME_STYLE = {
    ["WIDTH"] = 350
}

local mainFrame, tabs, minimizeFunc

function addon:showDirections() tabs:SelectTab("directions") end

local function maximizeWindow() mainFrame:Minimize(false) end

local function afterSelectTab(tabs, callbackName, tabName)
    tabs:ReleaseChildren()

    minimizeFunc = function (minimized) end -- dummy function that does nothing in case tab panel doesn't minimize
    if tabName == "locations" then
        local searchPanel, minimizeSearchPanel = addon:SearchPanel(maximizeWindow)
        tabs:AddChild(searchPanel)
        minimizeFunc = minimizeSearchPanel
    elseif tabName == "directions" then
        tabs:AddChild(addon:DirectionsPanel(addon.AddonState.directions))
    end

    minimizeFunc(mainFrame:GetMinimized())
end


function addon:initGUI()
    -- main JJWindow
    mainFrame = AceGUI:Create("JJWindow")
    mainFrame.frame:SetParent(WorldMapFrame)
    mainFrame:SetTitle("JackJack")
    mainFrame:SetPoint("TOPLEFT", "WorldMapFrame", "TOPRIGHT")
    mainFrame:SetWidth(MAIN_FRAME_STYLE.WIDTH)
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

    -- set minimize behavior
    mainFrame:SetCallback("OnMinimizeStateChanged", function(_, _, minimize, maximizedHeight)
        addon.Settings.profile.gui.maximizedHeight = maximizedHeight
        addon.Settings.profile.gui.minimized = minimize
        minimizeFunc(minimize)
    end)
    
    -- restore gui state from saved variables
    mainFrame:SetMaximizedHeight(addon.Settings.profile.gui.maximizedHeight)
    mainFrame:Minimize(addon.Settings.profile.gui.minimized)
    minimizeFunc(addon.Settings.profile.gui.minimized)
end