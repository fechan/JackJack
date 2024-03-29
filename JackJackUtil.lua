local addonName, addon = ...

function table.slice(tbl, first, last, step)
    local sliced = {}
    for i = first or 1, last or #tbl, step or 1 do
      sliced[#sliced+1] = tbl[i]
    end
    return sliced
end

--- Get a dataset safe ID for a record in a dataset that uniquely identifies it across all datasets
-- @param datasetName   Unique name of the dataset
-- @param recordId      ID of the record within the dataset
-- @return              Dataset safe ID
addon.getDatasetSafeID = function(datasetName, recordId)
    return datasetName .. ":" .. recordId
end

--- Get the record in a dataset from its dataset safe ID
-- @param   datasetSafeID Dataset safe ID
-- @return  Record from the dataset
-- @return  Dataset name
addon.getRecordFromDatasetSafeID = function(datasetSafeID)
    local datasetName, recordId = strsplit(":", datasetSafeID, 2) -- string.find(datasetSafeID, "(.+):(.+)")
    return addon[datasetName][tonumber(recordId)], datasetName
end

addon.playerMeetsPortalRequirements = function(playerConditionId)
    if playerConditionId == 0 then
        return true
    end
    local playerCondition = addon.JJPlayerCondition[playerConditionId]

    -- check player race
    local _, _, raceId = UnitRace("player")
    local playerMeetsRaceReq = playerCondition["race_" .. raceId] == 1

    -- check if player can use any of the spells
    local spell0, spell1 = playerCondition["SpellID0"], playerCondition["SpellID1"]
    local spell0Known, spell1Known = true, true
    local spell0Usable, spell1Usable, spell0NoMana, spell1NoMana = true, true, false, false
    if spell0 ~= 0 then
        spell0Known = IsSpellKnown(spell0)
        spell0Usable, spell0NoMana = IsUsableSpell(spell0)
    end
    if spell1 ~= 0 then
        spell1Known = IsSpellKnown(spell1)
        spell1Usable, spell1NoMana = IsUsableSpell(spell1)
    end
    
    local playerMeetsSpellReq = (spell0Known and spell0Usable) or (spell1Known and spell1Usable)

    return playerMeetsRaceReq and playerMeetsSpellReq
end

addon.playerCanUseTaxiNode = function(taxiNode)
    local faction, _ = UnitFactionGroup("player")
    return (faction == "Alliance" and taxiNode["A"] == 1) or (faction == "Horde" and taxiNode["H"] == 1)
end

addon.getInstanceTypeName = function(instanceType)
    return ({[0] = "Not instanced", "Party dungeon", "Raid dungeon", "PvP battlefield", "Arena battlefield", "Scenario"})[tonumber(instanceType)]
end

addon.getLocationDisplayName = function(location)
    if location.Transport then -- if Transport is defined then this is a direction
        if location.Transport == "taxinode-geton" then
            return location.DirectionNbr .. ". Take the flight master from " .. location.Name_lang
        elseif location.Transport == "taxinode" then
            return location.DirectionNbr .. ". Keep riding through " .. location.Name_lang
        elseif location.Transport == "taxinode-getoff" then
            return location.DirectionNbr .. ". Get off the flight master at " .. location.Name_lang
        elseif location.Transport == "destination" then
            return location.DirectionNbr .. ". Walk/fly to arrive at ".. location.Name_lang
        else
            return location.DirectionNbr .. ". " .. location.Name_lang
        end
    else
        if location.AreaName_lang == "" or location.AreaName_lang == nil then
            return location.Name_lang .. "\n(" .. location.MapName_lang .. ")"
        elseif location.AreaName_lang == location.MapName_lang then
            return location.Name_lang .. "\n(" .. location.MapName_lang .. ")"
        else
            return location.Name_lang .. "\n(" .. location.AreaName_lang .. ", " .. location.MapName_lang .. ")"
        end
    end
end