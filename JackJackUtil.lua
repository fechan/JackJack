local addonName, addon = ...

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
    local datasetName, recordId = string.match(datasetSafeID, "(.+):(.+)")
    return addon[datasetName][tonumber(recordId)], datasetName
end