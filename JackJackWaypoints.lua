local addonName, addon = ...

local AUTO_REMOVE_WAYPOINTS = false -- TODO: make this a configuration option

if AUTO_REMOVE_WAYPOINTS then
    local waypointUpdateFrame = CreateFrame("FRAME", "JJWaypointUpdateFrame");
    waypointUpdateFrame:SetScript("OnUpdate", function ()
        local waypoints = addon.AddonState.directionWaypoints
        local playerMap, x, y = TomTom:GetCurrentPlayerPosition()

        for i=#waypoints, 1, -1 do -- i points to the most advanced direction in the list
            if waypoints[i] == nil then break end
            
            local uid, map = unpack(waypoints[i])
            if map == playerMap then
                -- if a waypoint is supposed to be on the same map as the player but we can't find the
                -- distance, the waypoint UID is invalid (e.g. removed by player)
                if TomTom:GetDistanceToWaypoint(uid) == nil then
                    waypoints[i] = nil
                    break
                end

                for j=i, 1, -1 do -- start checking if the less advanced directions are farther away
                    if waypoints[j] == nil then break end
                    local uid2, map2 = unpack(waypoints[j])

                    if TomTom:GetDistanceToWaypoint(uid2) == nil then waypoints[j] = nil -- remove waypoint if it's invalid
                    elseif TomTom:GetDistanceToWaypoint(uid2) > TomTom:GetDistanceToWaypoint(uid) then
                        TomTom:RemoveWaypoint(uid2)
                        waypoints[j] = nil
                    end
                end
            end        
        end
    end);
end

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

local function getDirectionDisplayName(direction)
    if direction.Transport == "taxinode-geton" then
        return "Take the flight master from " .. direction.Name_lang
    elseif direction.Transport == "taxinode" then
        return "Keep riding through " .. direction.Name_lang
    elseif direction.Transport == "taxinode-getoff" then
        return "Get off the flight master at " .. direction.Name_lang
    elseif direction.Transport == "destination" then
        return "Walk/fly to arrive at ".. direction.Name_lang
    else
        return direction.Name_lang
    end
end

function addon:createDirectionWaypointFor(direction)
    local uiMapId, x, y = addon:getBestZoomMapPositionFor(direction)
    local uid = TomTom:AddWaypoint(uiMapId, x, y, {
        title = direction.DirectionNbr .. ". " .. getDirectionDisplayName(direction),
        source = "JackJack (directions)",
        persistent = true,
        minimap = true,
        world = true,
        crazy = true
    })
    addon.AddonState.directionWaypoints[direction.DirectionNbr] = {uid, uiMapId}
end

function addon:clearDirectionWaypoints()
    for directionNbr, directionWaypoint in pairs(addon.AddonState.directionWaypoints) do
        local uid, waypointMap = unpack(directionWaypoint)
        TomTom:RemoveWaypoint(uid)
    end
    addon.AddonState.directionWaypoints = {}
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