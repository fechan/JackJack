local addonName, addon = ...

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