local addonName, addon = ...

LOADING_SCREEN_WEIGHT = 1000 --TODO: set this to something sane

local function distance3d(x1, y1, z1, x2, y2, z2)
    local xd = x1 - x2
    local yd = y1 - y2
    local zd = z1 - z2
    return math.sqrt(xd * xd + yd * yd + zd * zd)
end

local function playerMeetsPortalRequirements(playerConditionId)
    if playerConditionId == 0 then
        return true
    end
    local _, _, raceId = UnitRace("player")
    return addon.PlayerConditionExpanded[playerConditionId]["race_" .. raceId] == 1
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
        for adjacentNodeId, adjacentNode in pairs(addon.WaypointNodeWithLocation) do
            if adjacentNode["MapID"] == playerContinent then
                table.insert(adjacentNodes, {
                    nodeId = adjacentNodeId,
                    distance = CalculateDistance(playerPosition.x, playerPosition.y, adjacentNode["Pos0"], adjacentNode["Pos1"]) -- can't get player Z so it has to be 2D
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

    local nodeX = addon.WaypointNodeWithLocation[nodeId]["Pos0"]
    local nodeY = addon.WaypointNodeWithLocation[nodeId]["Pos1"]
    local nodeZ = addon.WaypointNodeWithLocation[nodeId]["Pos2"]
    local nodeMapID = addon.WaypointNodeWithLocation[nodeId]["MapID"]

    -- step 1: get all the edges that start at the nodeId and add the end node to the adjacentNodes
    for edgeId, edge in pairs(addon.WaypointEdgeReduced) do
        if edge["Start"] == nodeId then
            if playerMeetsPortalRequirements(edge["PlayerConditionID"]) then
                table.insert(adjacentNodes, {
                    nodeId = edge["End"],
                    distance = LOADING_SCREEN_WEIGHT
                })
            end
        end
    end
    -- step 2: get all the nodes that are on the same continent as the nodeId and add them to the adjacentNodes
    for adjacentNodeId, adjacentNode in pairs(addon.WaypointNodeWithLocation) do
        if adjacentNode["MapID"] == nodeMapID then
            table.insert(adjacentNodes, {
                nodeId = adjacentNodeId,
                distance = distance3d(nodeX, nodeY, nodeZ, adjacentNode["Pos0"], adjacentNode["Pos1"], adjacentNode["Pos2"])
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

addon.getDirections = function(destinationX, destinationY, destinationContinent, destinationName)
    local dist = {}
    local prev = {}
    local Q = {}
    for nodeId, node in pairs(addon.WaypointNodeWithLocation) do
        dist[nodeId] = math.huge
        prev[nodeId] = nil
        table.insert(Q, nodeId)
    end
    dist["destination"] = math.huge
    prev["destination"] = nil
    table.insert(Q, "destination")
    dist["player"] = 0
    prev["player"] = "player"
    table.insert(Q, "player")

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
        if addon.WaypointNodeWithLocation[nodeId] ~= nil then
            local nodeInfo = addon.WaypointNodeWithLocation[nodeId]
            globalCoords = CreateVector2D(nodeInfo["Pos0"], nodeInfo["Pos1"])
            uiMapId, mapPosition = C_Map.GetMapPosFromWorldPos(nodeInfo["MapID"], globalCoords)
            name = nodeInfo["Name_lang"]
        else
            globalCoords = CreateVector2D(destinationX, destinationY)
            uiMapId, mapPosition = C_Map.GetMapPosFromWorldPos(destinationContinent, globalCoords)
            name = "Fly or walk to " .. destinationName
        end
        direction["Name_lang"] = name
        direction["uiMapId"] = uiMapId
        direction["x"] = mapPosition.x
        direction["y"] = mapPosition.y
        
        table.insert(directions, direction)
    end

    return directions
end