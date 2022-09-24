local addonName, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

local DEFAULT_STYLE = {
    ["BUTTON_SIZE"] = 45,
    ["ICON_SIZE"] = 45 / 2
}

local function addTooltip(button, location, style)
    -- create tooltip
    local tooltip = addon:getGlobalTooltip()
    button:SetUserData("tooltip", tooltip)
    tooltip:ClearLines()
    tooltip:SetOwner(button.frame, "ANCHOR_RIGHT", 0, -style.BUTTON_SIZE)

    -- set text content
    tooltip:AddLine("Get directions to " .. location.Name_lang)
    tooltip:AddLine("This may take several seconds.")
    tooltip:AddLine(" ")
    tooltip:AddLine("Warning: this is occasionally wrong.")

    tooltip:Show()
end

function addon:DirectionsButton(location, style)
    style = style or {}
    setmetatable(style, {__index = DEFAULT_STYLE})

    local button = AceGUI:Create("IconButton")

    local settings = addon.Settings.profile.directions
    button:SetCallback("OnClick", function() 
        addon.AddonState.directions = addon:getDirections(location, settings.includeTaxi, settings.loadingScreenSeconds)
        addon:showDirections()
    end)

    button:SetCallback("OnEnter", function(button) addTooltip(button, location, style) end)
    button:SetCallback("OnLeave", function(button) button:GetUserData("tooltip"):Release() end)

    button:SetImage("Interface\\AddOns\\JackJack\\directions")
    button:SetImageSize(style.ICON_SIZE, style.ICON_SIZE)
    button:SetHeight(style.BUTTON_SIZE)
    button:SetRelativeWidth(style.RELATIVE_WIDTH)
    return button
end