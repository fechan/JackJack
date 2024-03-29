local addonName, addon = ...

--- Create the JackJack minimap button
-- @param onclick   Callback function to call when button clicked
function addon:createMinimapButton(onclick)
    local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("JackJackDataBroker", {
        type = "data source",
        text = "JackJack",
        icon = "Interface\\AddOns\\JackJack\\minimapicon",
        OnClick = onclick,
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine("JackJack")
        end,
    })

    local icon = LibStub("LibDBIcon-1.0")
    icon:Register("JackJackDataBroker", miniButton, JackJackDataBroker)

    return icon
end