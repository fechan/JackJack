local addonName, addon = ...

LOADING_SCREEN_WEIGHT = 1000 --TODO: set this to something sane

local function distance3d(x1, y1, z1, x2, y2, z2)
    local xd = x1 - x2
    local yd = y1 - y2
    local zd = z1 - z2
    return math.sqrt(xd * xd + yd * yd + zd * zd)
end

local function playerMeetsPortalRequirements(playerConditionId)
    local raceId = UnitRace("player")
    return addon.PlayerConditionExpanded[playerConditionId]["race_" .. raceId] == 1
end

local function getAdjacentNodes(nodeId, destinationX, destinationY, destinationContinent)
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

    if nodeId == "destination" then
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

addon.getDirections = function(destinationX, destinationY, destinationContinent)
    print("starting dijkstra")
    -- the starting point of Dijkstra's algorithm is always the player's current position
    local dist = {}
    local prev = {}
    dist["player"] = 0

    local Q = addon.PriorityQueue()
    for nodeId, node in pairs(addon.WaypointNodeWithLocation) do
        dist[nodeId] = math.huge
        prev[nodeId] = nil
        Q:put(nodeId, math.huge)
    end
    -- add destination to the queue
    dist["destination"] = math.huge
    prev["destination"] = nil
    Q:put("destination", math.huge)
    -- add player (start) to the queue
    dist["player"] = 0
    prev["player"] = nil
    Q:put("player", 0)

    while Q:size() > 0 do
        local u = Q:pop()
        local adjacentNodes = getAdjacentNodes(u, destinationX, destinationY, destinationContinent)
        for _, adjacentNode in pairs(adjacentNodes) do
            local v = adjacentNode["nodeId"]
            local alt = dist[u] + adjacentNode["distance"]
            if alt < dist[v] then
                dist[v] = alt
                prev[v] = u
                Q:update(v, alt)
            end
        end
    end

    local path = {}
    local nodeId = "destination"
    while nodeId ~= "player" do
        table.insert(path, nodeId)
        nodeId = prev[nodeId]
        if nodeId == nil then
            print("no path")
            break
        end
    end
    for i, nodeId in pairs(path) do
        if addon.WaypointNodeWithLocation[nodeId] ~= nil then
            print(addon.WaypointNodeWithLocation[nodeId]["Name_lang"])
        else
            print(nodeId)
        end
    end
end