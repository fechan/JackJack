local addonName, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

STYLE = {
    ["LOCATIONBTN"] = {
        ["RELATIVE_WIDTH"] = .85,
        ["FULLWIDTH"] = false
    },
    ["DIRECTIONSBTN"] = {
        ["RELATIVE_WIDTH"] = .15
    }
}

function addon:SearchResult(location)
    local searchResult = AceGUI:Create("SimpleGroup")
    searchResult:SetFullWidth(true)
    searchResult:SetLayout("Flow")

    local locationButton = addon:LocationButton(location, STYLE.LOCATIONBTN)
    searchResult:AddChild(locationButton)

    local directionsButton = addon:DirectionsButton(location, STYLE.DIRECTIONSBTN)
    searchResult:AddChild(directionsButton)

    return searchResult
end