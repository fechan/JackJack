-- lib imports
local hbd = LibStub("HereBeDragons-2.0")

-- set addon namespace
local addonName, addon = ...

-- slash commands
SLASH_JACKJACK1 = "/jackjack"
SLASH_JACKJACK2 = "/jj"

SlashCmdList["JACKJACK"] = function(msg, editBox)
    local locationName = msg
    for rowNumber, poi in pairs(addon.areapoi) do
        if poi["Name_lang"]:lower() == locationName:lower() then
            local global_coords = CreateVector2D(poi["Pos0"], poi["Pos1"])
            local uiMapId, mapPosition = C_Map.GetMapPosFromWorldPos(poi["ContinentID"], global_coords)
            local waypointUid = TomTom:AddWaypoint(uiMapId, mapPosition.x, mapPosition.y, {
                title = poi["Name_lang"],
                source = "JackJack",
                persistent = true,
                minimap = true,
                world = true,
                crazy = true
            })
            print("Added waypoint for " .. poi["Name_lang"])
        end
    end
end