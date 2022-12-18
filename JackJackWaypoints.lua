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
        local waypointSettings = addon.Settings.profile.waypoints
        local waypoints = addon.AddonState.directionWaypoints

        --- Implementation of the auto remove waypoints feature.
        --  Steps backwards to determine the most advanced waypoint the player is closest to
        --  then removes all waypoints before it.
        local playerMap, x, y = TomTom:GetCurrentPlayerPosition()
        if (waypointSettings.autoRemove and #waypoints > 0
                and playerMap) then -- playerMap will be nil if you're in an instance (restricted), so we don't auto remove waypoints in those
            local waypoints = addon.AddonState.directionWaypoints

            local minDistance = math.huge
            local minDistanceWaypoint

            for i=#waypoints, 1, -1 do -- i points to the most advanced direction in the list
                if waypoints[i] == nil then break end
                
                local uid = waypoints[i]
                local map = uid[1]
                if map == playerMap then
                    local distance = TomTom:GetDistanceToWaypoint(uid)

                    -- if a waypoint is supposed to be on the same map as the player but we can't find the
                    -- distance, the waypoint UID is invalid (e.g. removed by player)
                    if distance == nil then
                        waypoints[i] = nil
                    else
                        if distance < minDistance then
                            minDistance = distance
                            minDistanceWaypoint = i
                        end
                    end
                end
            end

            if minDistanceWaypoint then
                for i=minDistanceWaypoint-1, 1, -1 do
                    local uid = waypoints[i]
                    TomTom:RemoveWaypoint(uid)
                    waypoints[i] = nil
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
    local focusLocation = addon.Settings.profile.interface.showLocationsOnWorldMapOnHover

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

    if focusLocation then
        WorldMapFrame:SetMapID(uiMapId)
    end

    local destroyCallback = function()
        TomTom:RemoveWaypoint(tempWaypointUid)
        if focusLocation then
            WorldMapFrame:SetMapID(oldUiMapId)
        end
    end

    return destroyCallback
end