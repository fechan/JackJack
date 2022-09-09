local addonName, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

function addon:DirectionsPanel()
    local temp = AceGUI:Create("Label")
    temp:SetText("directions tab")
    return temp
end