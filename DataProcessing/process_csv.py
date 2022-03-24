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
WaypointNode = pd.read_csv("WaypointNode.csv", usecols=["ID", "Name_lang", "SafeLocID", "Field_8_2_0_30080_005"])
# WaypointSafeLocs: Locations of portals
WaypointSafeLocs = pd.read_csv("WaypointSafeLocs.csv")

WaypointNode_Loc = (pd.merge(WaypointNode, WaypointSafeLocs,
                            how="inner", # exclude portals that don't have a set location (e.g. mage portals)
                            left_on="SafeLocID",
                            right_on="ID",
                            suffixes=["", "_WSL"])
                        .drop(columns=["ID_WSL", "SafeLocID"])
                        .rename(columns={"Field_8_2_0_30080_005": "Type"}))
WaypointNode_Loc.to_csv("WaypointNodeWithLocation.csv", index=False)

# WaypointEdge: Portal connections
WaypointEdge = pd.read_csv("WaypointEdge.csv", usecols=["Start", "End", "PlayerConditionID"])

# remove edges that involve start or end points not in the WaypointNode_Loc table (removes mage portal edges etc.)
WaypointEdgeReduced = WaypointEdge[WaypointEdge.Start.isin(WaypointNode_Loc.ID) & WaypointEdge.End.isin(WaypointNode_Loc.ID)]
WaypointEdgeReduced.to_csv("WaypointEdgeReduced.csv", index=False)

# PlayerCondition: Prerequisites for using a portal connection. Keep this separate from the WaypointEdge because otherwise
# there would be a lot of duplicate data
PlayerCondition = pd.read_csv("PlayerCondition.csv", usecols=["ID", "RaceMask"])
PlayerCondition_edgeonly = PlayerCondition[PlayerCondition.ID.isin(WaypointEdge.PlayerConditionID)] # only keep the ones that are in the WaypointEdge table

ChrRaces = pd.read_csv("ChrRaces.csv", usecols=["ID", "PlayableRaceBit"])
ChrRaces = ChrRaces[ChrRaces["PlayableRaceBit"] != -1]

def in_race_bit_mask(bitmask, raceID):
    """Determines if a character with raceID can use a portal with bitmask"""
    if bitmask == 0: return 1
    race_bit = ChrRaces[ChrRaces.ID == raceID].PlayableRaceBit
    return int(bitmask & (2**race_bit) == (2**race_bit))

def expand_racemask(PlayerCondition):
    """Expands the RaceMask in PlayerCondition into multiple binary (1/0) columns"""
    newdf = PlayerCondition.copy()
    for index, race in ChrRaces.iterrows():
        newdf["race_" + str(race["ID"])] = newdf.apply(lambda x, y: in_race_bit_mask(x.RaceMask, y), args=([race["ID"]]), axis=1)
    return newdf

(expand_racemask(PlayerCondition_edgeonly)
    .drop(columns=["RaceMask"])
    .to_csv("PlayerConditionExpanded.csv", index=False))