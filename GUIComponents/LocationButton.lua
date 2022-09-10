local addonName, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

local DEFAULT_STYLE = {
    ["HEIGHT"] = 45,
    ["FULLWIDTH"] = true
}

--- Get the display name for a location
-- @param   location    Location to get display name for
-- @return  displayName Display name
local function getLocationDisplayName(location)
    if location.AreaName_lang == "" or location.AreaName_lang == nil then
        return location.Name_lang .. "\n(" .. location.MapName_lang .. ")"
    elseif location.AreaName_lang == location.MapName_lang then
        return location.Name_lang .. "\n(" .. location.MapName_lang .. ")"
    else
        return location.Name_lang .. "\n(" .. location.AreaName_lang .. ", " .. location.MapName_lang .. ")"
    end
end

function addon:LocationButton(location, style)
    style = style or {}
    setmetatable(style, {__index = DEFAULT_STYLE})

    local button = AceGUI:Create("Button")

    button:SetCallback("OnClick", function() addon:createWaypointFor(location) end)

    button:SetCallback("OnEnter", function(button)
        local destroyTempWaypoint = addon:createAndFocusTempWaypointFor(location)
        button:SetUserData("destroyTempWaypoint", destroyTempWaypoint)

        local tooltip = addon:getGlobalTooltip()
        button:SetUserData("tooltip", tooltip)
        tooltip:ClearLines()
        tooltip:SetOwner(button.frame, "ANCHOR_RIGHT", 0, -style.HEIGHT)
        tooltip:AddLine(location.Name_lang)
        tooltip:Show()
    end)
    
    button:SetCallback("OnLeave", function(button)
        button:GetUserData("destroyTempWaypoint")()
        button:GetUserData("tooltip"):Release()
    end)

    button:SetText(getLocationDisplayName(location))
    button:SetHeight(style.HEIGHT)
    if style.FULLWIDTH then
        button:SetFullWidth(style.FULLWIDTH)
    else
        button:SetRelativeWidth(style.RELATIVE_WIDTH)
    end

    return button
end