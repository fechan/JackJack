local addonName, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

--- Factory method returning a scrollable list of widgets
-- @return list             The actual list you append widgets to
-- @return scrollContainer  The container for the list that enables scrolling
function addon:ScrollingList()
    local scrollContainer = AceGUI:Create("SimpleGroup")
    scrollContainer:SetLayout("Fill")
    
    local list = AceGUI:Create("ScrollFrame")
    list:SetLayout("List")
    scrollContainer:AddChild(list)
    
    return list, scrollContainer
end