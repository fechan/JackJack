local addonName, addon = ...

LOADING_SCREEN_WEIGHT = 1000 --TODO: set this to something sane

local function playerMeetsPortalRequirements(playerConditionId)
    if playerConditionId == 0 then
        return true
    end
    local _, _, raceId = UnitRace("player")
    return addon.JJPlayerCondition[playerConditionId]["race_" .. raceId] == 1
end

local function getAdjacentNodes(nodeId, destinationX, destinationY, destinationContinent)
    if nodeId == "destination" or nodeId == nil then
        return {}
    end
    
    local adjacentNodes = {} -- array of {nodeId, distance}
    if nodeId == "player" then
        local playerMap = C_Map.GetBestMapForUnit("player")
        local playerMapPosition = C_Map.GetPlayerMapPosition(playerMap, "player")
        local playerContinent, playerPosition = C_Map.GetWorldPosFromMapPos(playerMap, playerMapPosition)

        -- get all the WaypointNodes in the same continent as the player
        for adjacentNodeId, adjacentNode in pairs(addon.JJWaypointNode) do
            if adjacentNode["MapID"] == playerContinent then
                table.insert(adjacentNodes, {
                    nodeId = addon.getDatasetSafeID("JJWaypointNode", adjacentNodeId),
                    distance = CalculateDistance(playerPosition.x, playerPosition.y, adjacentNode["Pos0"], adjacentNode["Pos1"])
                })
            end
        end
        -- if the destination is in the same continent, add it to the list
        if destinationContinent == playerContinent then
            table.insert(adjacentNodes, {
                nodeId = "destination",
                distance = CalculateDistance(playerPosition.x, playerPosition.y, destinationX, destinationY)
            })
        end
        return adjacentNodes
    end

    local nodeInfo, _ = addon.getRecordFromDatasetSafeID(nodeId)
    local nodeX = nodeInfo["Pos0"]
    local nodeY = nodeInfo["Pos1"]
    local nodeMapID = nodeInfo["MapID"]

    -- step 1: get all the edges that start at the nodeId and add the end node to the adjacentNodes
    for edgeId, edge in pairs(addon.JJWaypointEdge) do
        if addon.getDatasetSafeID("JJWaypointNode", edge["Start"]) == nodeId then
            if playerMeetsPortalRequirements(edge["PlayerConditionID"]) then
                table.insert(adjacentNodes, {
                    nodeId = addon.getDatasetSafeID("JJWaypointNode", edge["End"]),
                    distance = LOADING_SCREEN_WEIGHT
                })
            end
        end
    end
    -- step 2: get all the nodes that are on the same continent as the nodeId and add them to the adjacentNodes
    for adjacentNodeId, adjacentNode in pairs(addon.JJWaypointNode) do
        if adjacentNode["MapID"] == nodeMapID then
            table.insert(adjacentNodes, {
                nodeId = addon.getDatasetSafeID("JJWaypointNode", adjacentNodeId),
                distance = CalculateDistance(nodeX, nodeY, adjacentNode["Pos0"], adjacentNode["Pos1"])
            })
        end
    end
    -- step 3: if the destination is on the same continent as the nodeId, add it to the list
    if destinationContinent == nodeMapID then
        table.insert(adjacentNodes, {
            nodeId = "destination",
            distance = CalculateDistance(nodeX, nodeY, destinationX, destinationY)
        })
    end
    return adjacentNodes
end

local function getNodeWithMinDist(Q, dist)
    local minDist = math.huge
    local minNode = nil
    local minNodeIndex = nil
    for i = 1, #Q do
        if dist[Q[i]] < minDist then
            minDist = dist[Q[i]]
            minNode = Q[i]
            minNodeIndex = i
        end
    end
    return minNodeIndex, minNode
end

local function addNodeToDijkstraGraph(nodeId, distTable, dist, prevTable, prev, Q)
    distTable[nodeId] = dist
    prevTable[nodeId] = prev
    table.insert(Q, nodeId)
end

addon.getDirections = function(destinationX, destinationY, destinationContinent, destinationName)
    local dist = {}
    local prev = {}
    local Q = {}
    for waypointNodeId, node in pairs(addon.JJWaypointNode) do
        local nodeId = addon.getDatasetSafeID("JJWaypointNode", waypointNodeId)
        addNodeToDijkstraGraph(nodeId, dist, math.huge, prev, nil, Q)
    end
    addNodeToDijkstraGraph("destination", dist, math.huge, prev, nil, Q)
    addNodeToDijkstraGraph("player", dist, 0, prev, "player", Q)

    while #Q > 0 do
        local uIndex, u = getNodeWithMinDist(Q, dist)
        table.remove(Q, uIndex)
        if u == "destination" then
            break
        end
        local adjacentNodes = getAdjacentNodes(u, destinationX, destinationY, destinationContinent)
        for _, adjacentNode in pairs(adjacentNodes) do
            local v = adjacentNode["nodeId"]
            local alt = dist[u] + adjacentNode["distance"]
            if alt < dist[v] then
                dist[v] = alt
                prev[v] = u
            end
        end
    end

    -- reconstruct the path
    local path = {}
    local nodeId = "destination"
    while nodeId ~= "player" do
        table.insert(path, nodeId)
        nodeId = prev[nodeId]
        if nodeId == nil then
            return nil
        end
    end

    local directions = {}
    for _, nodeId in ipairs(path) do
        local direction = {}
        local globalCoords, uiMapId, mapPosition, name
        local shouldAddDirection = true
        if nodeId ~= "destination" and nodeId ~= "player" and addon.getRecordFromDatasetSafeID(nodeId) ~= nil then
            local nodeInfo = addon.getRecordFromDatasetSafeID(nodeId)

            -- skip directions that are a portal exit (Type=2), since the player will always be there
            -- if they went through the entrance. Also some of the names of portal exits are misleading
            if nodeInfo["Type"] ~= 2 then
                globalCoords = CreateVector2D(nodeInfo["Pos0"], nodeInfo["Pos1"])
                uiMapId, mapPosition = C_Map.GetMapPosFromWorldPos(nodeInfo["MapID"], globalCoords)
                name = nodeInfo["Name_lang"]
                shouldAddDirection = true
            else
                shouldAddDirection = false
            end
        else
            globalCoords = CreateVector2D(destinationX, destinationY)
            uiMapId, mapPosition = C_Map.GetMapPosFromWorldPos(destinationContinent, globalCoords)
            name = "Fly/walk to arrive at " .. destinationName
            shouldAddDirection = true
        end

        if shouldAddDirection then
            direction["Name_lang"] = name
            direction["uiMapId"] = uiMapId
            direction["x"] = mapPosition.x
            direction["y"] = mapPosition.y
            
            table.insert(directions, direction)
        end
    end

    return directions
end