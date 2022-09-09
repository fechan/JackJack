local addonName, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

local STYLE = {
    ["HEIGHT"] = 45
}

--- Get the display name for a location
-- @param   location    Location to get display name for
-- @return  displayName Display name
local function getLocationDisplayName(location)
    if location["AreaName_lang"] == "" or location["AreaName_lang"] == nil then
        return location["Name_lang"] .. "\n(" .. location["MapName_lang"] .. ")"
    elseif location["AreaName_lang"] == location["MapName_lang"] then
        return location["Name_lang"] .. "\n(" .. location["MapName_lang"] .. ")"
    else
        return location["Name_lang"] .. "\n(" .. location["AreaName_lang"] .. ", " .. location["MapName_lang"] .. ")"
    end
end

function addon:LocationButton(location)
    local button = AceGUI:Create("Button")

    button:SetCallback("OnClick", function() addon:createWaypointFor(location) end)

    button:SetText(getLocationDisplayName(location))
    button:SetFullWidth(true)
    button:SetHeight(STYLE.HEIGHT)

    return button
end