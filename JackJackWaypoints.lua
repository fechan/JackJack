local addonName, addon = ...

--- This may get added to TomTom in the future
local function SetActiveCrazyArrowWaypoint(uid)
    local data = uid
    local arrival = TomTom.profile.arrow.arrival
    TomTom:SetCrazyArrow(uid, arrival, data.title)
end

function addon:initWaypoints()
    local waypointSettings = addon.Settings.profile.waypoints

    local waypointEventListener = CreateFrame("FRAME", "waypointEventListener");
    waypointEventListener:RegisterEvent("PLAYER_ENTERING_WORLD")

    waypointEventListener:SetScript("OnEvent", function (self, event, ...)
        -- show the next directions waypoint when you load into a new zone
        local waypoints = addon.AddonState.directionWaypoints

        if event == "PLAYER_ENTERING_WORLD" and #addon.AddonState.directionWaypoints > 0 then
            local closestWaypoint = nil
            local closestDist = math.huge
            
            for i, waypoint in ipairs(waypoints) do
                local dist = TomTom:GetDistanceToWaypoint(waypoint)
                if dist and dist < closestDist then
                    closestDist = dist
                    closestWaypoint = waypoint
                end
            end

            if closestWaypoint then
                SetActiveCrazyArrowWaypoint(closestWaypoint)
            end
        end
    end)

    waypointEventListener:SetScript("OnUpdate", function ()
        if waypointSettings.autoRemoveWaypoints and #waypoints > 0 then
            local waypoints = addon.AddonState.directionWaypoints
            local playerMap, x, y = TomTom:GetCurrentPlayerPosition()

            for i=#waypoints, 1, -1 do -- i points to the most advanced direction in the list
                if waypoints[i] == nil then break end
                
                local uid = waypoints[i]
                local map = uid[1]
                if map == playerMap then
                    -- if a waypoint is supposed to be on the same map as the player but we can't find the
                    -- distance, the waypoint UID is invalid (e.g. removed by player)
                    if TomTom:GetDistanceToWaypoint(uid) == nil then
                        waypoints[i] = nil
                        break
                    end

                    for j=i, 1, -1 do -- start checking if the less advanced directions are farther away
                        if waypoints[j] == nil then break end
                        local uid2 = waypoints[j]
                        local map2 = uid2[1]

                        if TomTom:GetDistanceToWaypoint(uid2) == nil then waypoints[j] = nil -- remove waypoint if it's invalid
                        elseif TomTom:GetDistanceToWaypoint(uid2) > TomTom:GetDistanceToWaypoint(uid) then
                            TomTom:RemoveWaypoint(uid2)
                            waypoints[j] = nil
                        end
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

function addon:createDirectionWaypointFor(direction)
    local uiMapId, x, y = addon:getBestZoomMapPositionFor(direction)
    local uid = TomTom:AddWaypoint(uiMapId, x, y, {
        title = addon.getLocationDisplayName(direction),
        source = "JackJack (directions)",
        persistent = true,
        minimap = true,
        world = true,
        crazy = true
    })
    addon.AddonState.directionWaypoints[direction.DirectionNbr] = uid
end

function addon:clearDirectionWaypoints()
    for directionNbr, directionWaypoint in pairs(addon.AddonState.directionWaypoints) do
        TomTom:RemoveWaypoint(directionWaypoint)
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