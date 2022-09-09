local addonName, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

function addon:ScrollingList()
    local scrollContainer = AceGUI:Create("SimpleGroup")
    scrollContainer:SetLayout("Fill")
    
    local list = AceGUI:Create("ScrollFrame")
    list:SetLayout("List")
    scrollContainer:AddChild(list)
    
    return list, scrollContainer
end