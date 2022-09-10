local addonName, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

local DEFAULT_STYLE = {
    ["BUTTON_SIZE"] = 45,
    ["ICON_SIZE"] = 45 / 2
}

local function afterGetDirections(directions)
    for i = #directions, 1, -1 do
        print(#directions - i + 1, directions[i]["Name_lang"])
    end
end

function addon:DirectionsButton(location, style)
    style = style or {}
    setmetatable(style, {__index = DEFAULT_STYLE})

    local button = AceGUI:Create("IconButton")

    button:SetCallback("OnClick", function() 
        local directions = addon:getDirections(
            location.Pos0,
            location.Pos1,
            location.ContinentID,
            location.Name_lang
        )
        afterGetDirections(directions)
    end)

    button:SetImage("Interface\\AddOns\\JackJack\\directions")
    button:SetImageSize(style.ICON_SIZE, style.ICON_SIZE)
    button:SetHeight(style.BUTTON_SIZE)
    button:SetRelativeWidth(style.RELATIVE_WIDTH)
    return button
end