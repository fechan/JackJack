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
    if location.Transport ~= nil then
        if location.Transport == "taxinode-geton" then
            return location.DirectionNbr .. ". Take the flight master from " .. location.Name_lang
        elseif location.Transport == "taxinode" then
            return location.DirectionNbr .. ". Keep riding through " .. location.Name_lang
        elseif location.Transport == "taxinode-getoff" then
            return location.DirectionNbr .. ". Get off the flight master at " .. location.Name_lang
        elseif location.Transport == "destination" then
            return location.DirectionNbr .. ". Walk/fly to arrive at ".. location.Name_lang
        else
            return location.DirectionNbr .. ". " .. location.Name_lang
        end
    else
        if location.AreaName_lang == "" or location.AreaName_lang == nil then
            return location.Name_lang .. "\n(" .. location.MapName_lang .. ")"
        elseif location.AreaName_lang == location.MapName_lang then
            return location.Name_lang .. "\n(" .. location.MapName_lang .. ")"
        else
            return location.Name_lang .. "\n(" .. location.AreaName_lang .. ", " .. location.MapName_lang .. ")"
        end
    end
end

local function addTooltip(button, location, style)
    -- create tooltip
    local tooltip = addon:getGlobalTooltip()
    button:SetUserData("tooltip", tooltip)
    tooltip:ClearLines()
    tooltip:SetOwner(button.frame, "ANCHOR_RIGHT", 0, -style.HEIGHT)

    -- set text content
    tooltip:AddLine(getLocationDisplayName(location))
    if location.Description_lang ~= "" and location.Description_lang ~= nil then
        tooltip:AddLine("Description: " .. location.Description_lang)
    end
    if location.Origin ~= "" then
        tooltip:AddLine("Dataset: " .. location.Origin)
    end

    tooltip:Show()
end

function addon:LocationButton(location, style)
    style = style or {}
    setmetatable(style, {__index = DEFAULT_STYLE})

    local button = AceGUI:Create("Button")

    button:SetCallback("OnClick", function() addon:createWaypointFor(location) end)

    button:SetCallback("OnEnter", function(button)
        local destroyTempWaypoint = addon:createAndFocusTempWaypointFor(location)
        button:SetUserData("destroyTempWaypoint", destroyTempWaypoint)
        addTooltip(button, location, style)
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