local addonName, addon = ...

--- Create a permanent TomTom waypoint for a location
-- @param location  Location to make a waypoint for
function addon:createWaypointFor(location)
    local uiMapId, x, y = addon:getBestZoomMapPositionFor(location)
    TomTom:AddWaypoint(uiMapId, x, y, {
        title = location.Name_lang,
        source = "JackJack",
        persistent = true,
        minimap = true,
        world = true,
        crazy = true
    })
end

--- Create a temporary TomTom waypoint for a location and focus on it on the map
-- @param   location        Location to make a waypoint for
-- @return  destroyCallback Function that destroys the temporary waypoint
function addon:createAndFocusTempWaypointFor(location)
    local uiMapId, x, y = addon:getBestZoomMapPositionFor(location)
    local tempWaypointUid = TomTom:AddWaypoint(uiMapId, x, y, {
        title = location.Name_lang .. " (temp)", -- (temp) is to prevent collisions with permanent waypoint, otherwise new waypoint won't be added
        source = "JackJack",
        persistent = false,
        minimap = true,
        world = true,
        crazy = false
    })
    local oldUiMapId = WorldMapFrame:GetMapID()
    WorldMapFrame:SetMapID(uiMapId)

    local destroyCallback = function()
        TomTom:RemoveWaypoint(tempWaypointUid)
        WorldMapFrame:SetMapID(oldUiMapId)
    end

    return destroyCallback
end