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
AreaPOI_joined = AreaPOI_joined[~AreaPOI_joined.Name_lang.str.startswith("[DEPRECATED]", na=False)]
AreaPOI_joined = AreaPOI_joined[~AreaPOI_joined.Name_lang.str.startswith("[Deprecated]", na=False)]
AreaPOI_joined["Origin"] = "AreaPOI (Points of Interest table)"

### Process TaxiNodes

# TaxiNodes: Flight points
TaxiNodes = pd.read_csv("TaxiNodes.csv", usecols=["Name_lang", "Pos[0]", "Pos[1]", "ContinentID"])
TaxiNodes_joined = (pd.merge(TaxiNodes, Map, how="left", left_on="ContinentID", right_on="ID", suffixes=["", "_Map"])
                   .drop(labels=["ID"], axis=1))
TaxiNodes_joined = TaxiNodes_joined[~TaxiNodes_joined.Name_lang.str.startswith("Quest")] # Guessing that these flight points only show up for quests
TaxiNodes_joined = TaxiNodes_joined[~TaxiNodes_joined.Name_lang.str.startswith("[Hidden]")]
TaxiNodes_joined = TaxiNodes_joined[~TaxiNodes_joined.Name_lang.str.startswith("[HIDDEN]")]
TaxiNodes_joined["Origin"] = "TaxiNodes (Flight points table)"

pd.concat([AreaPOI_joined, TaxiNodes_joined]).to_csv("JackJackLocations.csv", index=False)

### Process portals (for directions feature)
# To save on space, we will join WaypointEdge with WaypointNode in the addon and not here,
# since we need them separately anyway during the walking/cross-join part

# WaypointNode: Portal entrances and exits
WaypointNode = pd.read_csv("WaypointNode.csv", usecols=["ID", "Name_lang", "SafeLocID"])
# WaypointSafeLocs: Locations of portals
WaypointSafeLocs = pd.read_csv("WaypointSafeLocs.csv")

WaypointNode_Loc = (pd.merge(WaypointNode, WaypointSafeLocs,
                            how="inner", # exclude portals that don't have a set location (e.g. mage portals)
                            left_on="SafeLocID",
                            right_on="ID",
                            suffixes=["", "_WSL"])
                        .drop(columns=["ID_WSL", "SafeLocID"]))
WaypointNode_Loc.to_csv("WaypointNodeWithLocation.csv", index=False)

# WaypointEdge: Portal connections
WaypointEdge = pd.read_csv("WaypointEdge.csv", usecols=["Start", "End", "PlayerConditionID"])
# PlayerCondition: Prerequisites for using a portal connection
PlayerCondition = pd.read_csv("PlayerCondition.csv", usecols=["ID", "RaceMask"])

WaypointEdge_prereq = WaypointEdge.merge(PlayerCondition, how="inner", left_on="PlayerConditionID", right_on="ID").drop(columns=["ID", "PlayerConditionID"])
# remove edges that involve start or end points not in the WaypointNode_Loc table (removes mage portal edges etc.)
WaypointEdge_prereq = WaypointEdge_prereq[WaypointEdge_prereq.Start.isin(WaypointNode_Loc.ID) & WaypointEdge_prereq.End.isin(WaypointNode_Loc.ID)]

WaypointEdge_prereq.to_csv("WaypointEdgeWithRequirements.csv", index=False)
# TODO: Add prerequisite completed quest IDs to WaypointEdgeWithRequirements

ChrRaces = pd.read_csv("ChrRaces.csv", usecols=["ID", "PlayableRaceBit"])
ChrRaces = ChrRaces[ChrRaces["PlayableRaceBit"] != -1]
ChrRaces.to_csv("ChrRacesBitmasks.csv", index=False)