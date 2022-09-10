-- Tooltip.lua: Since AceGUI doesn't provide a Tooltip widget, and it would take
-- some effort to make an actual AceGUI widget for tooltips, this emulates the
-- API for one without actually being one.
-- Basically unlike Widgets, this file creates a single tooltip for the entire addon
-- which is never "released".
--
-- Instead of acquiring a tooltip via AceGUI:Create, you call addon:getGlobalTooltip
-- and you would ALSO need to call Tooltip:Show to show it.
--
-- Emulating the widget API makes it easy to migrate to a full widget implementation
-- if I ever make one, so switching is as easy as replacing getGlobalTooltip.

local addonName, addon = ...

local Tooltip = {
    ["frame"] = CreateFrame("GameTooltip", "JackJackLocationTooltip", UIParent, "GameTooltipTemplate")
}

function Tooltip:AddLine(text) self.frame:AddLine(text) end
function Tooltip:ClearLines() self.frame:ClearLines() end
function Tooltip:SetOwner(owner, anchor, ofsX, ofsY) self.frame:SetOwner(owner, anchor, ofsX, ofsY) end

function Tooltip:Release() self.frame:Hide() end
function Tooltip:Show() self.frame:Show() end -- This wouldn't exist in a real AceGUI widget

--- Get the tooltip instance GLOBAL to the entire addon
function addon:getGlobalTooltip()
    return Tooltip
end