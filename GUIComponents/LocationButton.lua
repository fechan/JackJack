local addonName, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

local DEFAULT_STYLE = {
    ["HEIGHT"] = 45,
    ["FULLWIDTH"] = true
}

local function addTooltip(button, location, style)
    -- create tooltip
    local tooltip = addon:getGlobalTooltip()
    button:SetUserData("tooltip", tooltip)
    tooltip:ClearLines()
    tooltip:SetOwner(button.frame, "ANCHOR_RIGHT", 0, -style.HEIGHT)

    -- set text content
    tooltip:AddLine(addon.getLocationDisplayName(location))
    if location.Description_lang ~= "" and location.Description_lang ~= nil then
        tooltip:AddLine("Description: " .. location.Description_lang)
    end

    if location.InstanceType then
        tooltip:AddLine("Instance type: " .. addon.getInstanceTypeName(location.InstanceType))
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

    button:SetText(addon.getLocationDisplayName(location))
    button:SetHeight(style.HEIGHT)
    if style.FULLWIDTH then
        button:SetFullWidth(style.FULLWIDTH)
    else
        button:SetRelativeWidth(style.RELATIVE_WIDTH)
    end

    return button
end