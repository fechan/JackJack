""" Process a bunch of CSVs from WoW.tools with location data and output them as a CSV
that can be converted to a Lua table for the addon.
"""

import pandas as pd

# Map: Continents (and instances?). We will need this for a lot of things.
# Map.MapDescription0_lang is for the Horde, and MapDescription1_lang is for the Alliance
# Map.ExpansionID is expansion ID (e.g. 7 is BfA)
Map = pd.read_csv("Map.csv", usecols=["ID", "MapName_lang"])

### Process AreaPOI

# AreaTable: Zones (and other locations)
AreaTable = pd.read_csv("AreaTable.csv", usecols=["ID", "AreaName_lang"])
# AreaPOI: Points of interest
AreaPOI = pd.read_csv("AreaPOI.csv", usecols=["Name_lang", "Description_lang", "Pos[0]", "Pos[1]", "ContinentID", "AreaID"])

AreaPOI_joined = (pd.merge(AreaPOI, Map, how="left", left_on="ContinentID", right_on="ID", suffixes=["", "_Map"])
                      .drop(labels=["ID"], axis=1))
AreaPOI_joined = (pd.merge(AreaPOI_joined, AreaTable, how="left", left_on="AreaID", right_on="ID", suffixes=["", "_AreaTable"])
                      .drop(labels=["ID", "AreaID"], axis=1))

### Process WaypointNode, WaypointSafeLocs

# WaypointNode: Portal entrances and exits
WaypointNode = (pd.read_csv("WaypointNode.csv", usecols=["Name_lang", "Field_8_2_0_30080_005", "SafeLocID"])
                    .rename(columns={"Field_8_2_0_30080_005": "NodeType"}))
# WaypointSafeLocs: Portal coordinates
WaypointSafeLocs = pd.read_csv("WaypointSafeLocs.csv", usecols=["ID", "Pos[0]", "Pos[1]", "MapID"])

WaypointSafeLocs_joined = (pd.merge(WaypointSafeLocs, Map, how="left", left_on="MapID", right_on="ID", suffixes=["", "_Map"])
                                .drop(labels=["ID_Map"], axis=1))
WaypointNode = WaypointNode[WaypointNode.NodeType == 2] # Keep only portal exits
WaypointNode_joined = (pd.merge(WaypointNode, WaypointSafeLocs_joined, how="left", left_on="SafeLocID", right_on="ID")
                           .drop(labels=["SafeLocID", "ID", "NodeType"], axis=1)
                           .rename(columns={"MapID": "ContinentID"}))

pd.concat([AreaPOI_joined, WaypointNode_joined]).to_csv("JackJackLocations.csv", index=False)