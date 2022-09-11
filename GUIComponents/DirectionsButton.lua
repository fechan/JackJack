local addonName, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

local DEFAULT_STYLE = {
    ["BUTTON_SIZE"] = 45,
    ["ICON_SIZE"] = 45 / 2
}

function addon:DirectionsButton(location, style)
    style = style or {}
    setmetatable(style, {__index = DEFAULT_STYLE})

    local button = AceGUI:Create("IconButton")

    button:SetCallback("OnClick", function() 
        addon.AddonState.directions = addon:getDirections(location)
        addon:showDirections()
    end)

    button:SetImage("Interface\\AddOns\\JackJack\\directions")
    button:SetImageSize(style.ICON_SIZE, style.ICON_SIZE)
    button:SetHeight(style.BUTTON_SIZE)
    button:SetRelativeWidth(style.RELATIVE_WIDTH)
    return button
end