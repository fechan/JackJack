local addonName, addon = ...

LOADING_SCREEN_WEIGHT = 1000 --TODO: set this to something sane
TAXI_SCALING = 0.5 -- this sets the weight of taxi edges to the actual distance times this TODO: set this to something sane


local function makeContinentWiseNodeTable(nodeList, continentColumnName)
    local continentWiseNodes = {}
    for nodeId, node in pairs(nodeList) do
        local continentId = node[continentColumnName]
        if not continentWiseNodes[continentId] then
            continentWiseNodes[continentId] = {}
        end
        continentWiseNodes[continentId][nodeId] = node
    end
    return continentWiseNodes
end

local continentWiseTaxiNodes = makeContinentWiseNodeTable(addon.JJTaxiNodes, "ContinentID")
local continentWiseWaypointNodes = makeContinentWiseNodeTable(addon.JJWaypointNode, "MapID")

local function getAdjacentNodes(nodeId, destinationX, destinationY, destinationContinent)
    if nodeId == "destination" or nodeId == nil then
        return {}
    end
    
    local adjacentNodes = {} -- array of {nodeId, distance}

    -- step 0: if the node is the player, get everything adjacent to the player and quit before step 1
    if nodeId == "player" then
        local playerMap = C_Map.GetBestMapForUnit("player")
        local playerMapPosition = C_Map.GetPlayerMapPosition(playerMap, "player")
        local playerContinent, playerPosition = C_Map.GetWorldPosFromMapPos(playerMap, playerMapPosition)

        -- get all the WaypointNodes in the same continent as the player
        local sameContinentNodes = continentWiseWaypointNodes[playerContinent]
        if sameContinentNodes ~= nil then
            for adjacentNodeId, adjacentNode in pairs(sameContinentNodes) do 
                adjacentNodes[#adjacentNodes+1] = {
                    nodeId = addon.getDatasetSafeID("JJWaypointNode", adjacentNodeId),
                    distance = CalculateDistance(playerPosition.x, playerPosition.y, adjacentNode["Pos0"], adjacentNode["Pos1"])
                }
            end
        end
        -- get all the TaxiNodes in the same continent as the player
        local sameContinentNodes = continentWiseTaxiNodes[playerContinent]
        if sameContinentNodes ~= nil then
            for adjacentNodeId, adjacentNode in pairs(sameContinentNodes) do
                if addon.playerCanUseTaxiNode(adjacentNode) then
                    adjacentNodes[#adjacentNodes+1] = {
                        nodeId = addon.getDatasetSafeID("JJTaxiNodes", adjacentNodeId),
                        distance = CalculateDistance(playerPosition.x, playerPosition.y, adjacentNode["Pos0"], adjacentNode["Pos1"])
                    }
                end
            end
        end
        -- if the destination is in the same continent, add it to the list
        if destinationContinent == playerContinent then
            adjacentNodes[#adjacentNodes+1] = {
                nodeId = "destination",
                distance = CalculateDistance(playerPosition.x, playerPosition.y, destinationX, destinationY)
            }
        end
        return adjacentNodes
    end

    local nodeInfo, nodeDataset = addon.getRecordFromDatasetSafeID(nodeId)
    local nodeX = nodeInfo["Pos0"]
    local nodeY = nodeInfo["Pos1"]
    local nodeMapID = nodeInfo["MapID"] or nodeInfo["ContinentID"]

    -- step 1: get all the edges that start at the nodeId and add the end node to the adjacentNodes
    if nodeDataset == "JJWaypointNode" then
        for edgeId, edge in pairs(addon.JJWaypointEdge) do
            if addon.getDatasetSafeID("JJWaypointNode", edge["Start"]) == nodeId then
                if addon.playerMeetsPortalRequirements(edge["PlayerConditionID"]) then
                    adjacentNodes[#adjacentNodes+1] = {
                        nodeId = addon.getDatasetSafeID("JJWaypointNode", edge["End"]),
                        distance = LOADING_SCREEN_WEIGHT
                    }
                end
            end
        end
    elseif nodeDataset == "JJTaxiNodes" then
        for edgeId, edge in pairs(addon.JJTaxiPath) do
            if addon.getDatasetSafeID("JJTaxiNodes", edge["FromTaxiNode"]) == nodeId then
                local toTaxiNodeId = edge["ToTaxiNode"]
                if addon.playerCanUseTaxiNode(addon.JJTaxiNodes[toTaxiNodeId]) then
                    adjacentNodes[#adjacentNodes+1] = {
                        nodeId = addon.getDatasetSafeID("JJTaxiNodes", toTaxiNodeId),
                        distance = edge["Distance"] * TAXI_SCALING
                    }
                end
            end
        end
    end
    -- step 2: get all the portals that are on the same continent as the nodeId and add them to the adjacentNodes
    local sameContinentNodes = continentWiseWaypointNodes[nodeMapID]
    if sameContinentNodes ~= nil then
        for adjacentNodeId, adjacentNode in pairs(sameContinentNodes) do
            adjacentNodes[#adjacentNodes+1] = {
                nodeId = addon.getDatasetSafeID("JJWaypointNode", adjacentNodeId),
                distance = CalculateDistance(nodeX, nodeY, adjacentNode["Pos0"], adjacentNode["Pos1"])
            }
        end
    end
    -- step 3: get all the taxi points that are on the same continent as the nodeId and add them to the adjacentNodes
    local sameContinentNodes = continentWiseTaxiNodes[nodeMapID]
    if sameContinentNodes ~= nil then
        for adjacentNodeId, adjacentNode in pairs(sameContinentNodes) do
            if addon.playerCanUseTaxiNode(adjacentNode) then
                adjacentNodes[#adjacentNodes+1] = {
                    nodeId = addon.getDatasetSafeID("JJTaxiNodes", adjacentNodeId),
                    distance = CalculateDistance(nodeX, nodeY, adjacentNode["Pos0"], adjacentNode["Pos1"])
                }
            end
        end
    end

    -- step 4: if the destination is on the same continent as the nodeId, add it to the list
    if destinationContinent == nodeMapID then
        adjacentNodes[#adjacentNodes+1] = {
            nodeId = "destination",
            distance = CalculateDistance(nodeX, nodeY, destinationX, destinationY)
        }
    end
    return adjacentNodes
end

local function addNodeToDijkstraGraph(nodeId, distTable, dist, prevTable, prev, Q)
    distTable[nodeId] = dist
    prevTable[nodeId] = prev
    -- table.insert(Q, nodeId)
    Q:insert(dist, nodeId)
end

--- Calculate taxi on/off/continue points and set the transport type IN PLACE
--  e.g. if the direction is to get on a taxi, the transport type is "taxinode-geton"
--       if the direction is to keep riding, the transport type is unchanged
-- @param directions List of directions
local function calculateTaxiTransportType(directions)
    for idx, direction in ipairs(directions) do
        if direction.Transport == "taxinode" then
            local prev = directions[idx - 1]
            local next = directions[idx + 1]
            if prev == nil then
                direction.Transport = "taxinode-geton"
            elseif prev.Transport ~= "taxinode" and prev.Transport ~= "taxinode-geton" then
                direction.Transport = "taxinode-geton"
            elseif next == nil or next.Transport ~= "taxinode" then
                direction.Transport = "taxinode-getoff"
            end
        end
    end
end

--- Get directions to a given location
--  You can have it run a callback on completion with the return value.
--  It is meant for non-blocking Dijkstra calculation which runs a single iteration
--  of Dijkstra's every time OnUpdate is called. (TODO: implement this)
-- @param location          Destination to get directions to
-- @param completedCallback Callback function after function completes
function addon:getDirections(location, completedCallback)
    local dist = {}
    local prev = {}
    local Q = addon.binaryheap.minUnique()
    for waypointNodeId, node in pairs(addon.JJWaypointNode) do
        local nodeId = addon.getDatasetSafeID("JJWaypointNode", waypointNodeId)
        addNodeToDijkstraGraph(nodeId, dist, math.huge, prev, nil, Q)
    end
    for taxiNodeId, node in pairs(addon.JJTaxiNodes) do
        local nodeId = addon.getDatasetSafeID("JJTaxiNodes", taxiNodeId)
        addNodeToDijkstraGraph(nodeId, dist, math.huge, prev, nil, Q)
    end
    addNodeToDijkstraGraph("destination", dist, math.huge, prev, nil, Q)
    addNodeToDijkstraGraph("player", dist, 0, prev, "player", Q)

    local directions = {}

    while Q:size() > 0 do
        local u, _ = Q:pop()
        if u == "destination" then
            break
        else
            local adjacentNodes = getAdjacentNodes(u, location.Pos0, location.Pos1, location.ContinentID)
            
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
    end

    -- reconstruct the path
    local path = {}
    local nodeId = "destination"
    while nodeId ~= "player" do
        table.insert(path, nodeId)
        nodeId = prev[nodeId]
        if nodeId == nil then
            return {["ErrorGettingTo"] = location}
        end
    end

    -- path reconstruction is in backwards order, so we iterate
    -- backwards as we process each mode to make it forwards again
    local directionNbr = 1
    for i = #path, 1, -1 do
        local nodeId = path[i]

        if nodeId ~= "player" then
            local nodeInfo, datasetName
            if nodeId == "destination" then
                nodeInfo = location
                datasetName = location.Origin
            else 
                nodeInfo, datasetName = addon.getRecordFromDatasetSafeID(nodeId)
            end
            
            local direction = {
                ["Name_lang"] =     nodeInfo.Name_lang,
                ["Pos0"] =          nodeInfo.Pos0,
                ["Pos1"] =          nodeInfo.Pos1,
                ["Origin"] =        datasetName,
                ["MapName_lang"] =  "placeholder", -- TODO: find this somehow
                ["ContinentID"] =   nodeInfo.ContinentID or nodeInfo.MapID,
                ["DirectionNbr"] =  directionNbr,
                ["Transport"] =     nil, -- depends
            }

            if datasetName == "JJWaypointNode" then
                if nodeInfo.Type ~= 2 then
                    direction.Transport = "portal"
                    directionNbr = directionNbr + 1
                    table.insert(directions, direction)
                end
            elseif datasetName == "JJTaxiNodes" then
                direction.Transport = "taxinode"
                directionNbr = directionNbr + 1
                table.insert(directions, direction)
            else
                direction.Transport = "destination"
                directionNbr = directionNbr + 1
                table.insert(directions, direction)
            end
        end
    end

    calculateTaxiTransportType(directions)

    if completedCallback then
        completedCallback(directions)
    end
    return directions
end