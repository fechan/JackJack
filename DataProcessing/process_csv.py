""" Process a bunch of CSVs from WoW.tools with location data and output them as a CSV
that can be converted to a Lua table for the addon.
"""

import pandas as pd

# Map: Continents (and instances?). We will need this for a lot of things.
# Map.MapDescription0_lang is for the Horde, and MapDescription1_lang is for the Alliance
# Map.ExpansionID is expansion ID (e.g. 7 is BfA)
Map = pd.read_csv("Map.csv", usecols=["ID", "MapName_lang", "InstanceType"])
Map.to_csv("JJMap.csv", index=False)

### Process AreaTable + AreaPOI --> JJAreaPOI

# AreaTable: Zones (and other locations)
AreaTable = pd.read_csv("AreaTable.csv", usecols=["ID", "AreaName_lang"])
# AreaPOI: Points of interest
AreaPOI = pd.read_csv("AreaPOI.csv", usecols=["Name_lang", "Description_lang", "Pos[0]", "Pos[1]", "ContinentID", "AreaID"])

JJAreaPOI = (AreaPOI.merge(AreaTable, how="left", left_on="AreaID", right_on="ID")
                    .drop(labels=["ID", "AreaID"], axis=1))
JJAreaPOI = JJAreaPOI[~JJAreaPOI.Name_lang.str.startswith("[DEPRECATED]", na=False)]
JJAreaPOI = JJAreaPOI[~JJAreaPOI.Name_lang.str.startswith("[Deprecated]", na=False)]
JJAreaPOI.to_csv("JJAreaPOI.csv", index=False)

### Process TaxiNodes --> JJTaxiNodes

# TaxiNodes: Flight points
TaxiNodes = pd.read_csv("TaxiNodes.csv", usecols=["ID", "Name_lang", "Pos[0]", "Pos[1]", "ContinentID", "MountCreatureID[0]", "MountCreatureID[1]"])
JJTaxiNodes = TaxiNodes[~TaxiNodes.Name_lang.str.startswith("Quest")] # Guessing that these flight points only show up for quests
JJTaxiNodes = JJTaxiNodes[~JJTaxiNodes.Name_lang.str.startswith("[Hidden]")]
JJTaxiNodes = JJTaxiNodes[~JJTaxiNodes.Name_lang.str.startswith("[HIDDEN]")]
JJTaxiNodes = JJTaxiNodes.set_index("ID")
# MountCreatureID[0] is >0 if allowed for alliance, MountCreateID[1] for horde
JJTaxiNodes["MountCreatureID[0]"] = (JJTaxiNodes["MountCreatureID[0]"] > 0).astype(int)
JJTaxiNodes["MountCreatureID[1]"] = (JJTaxiNodes["MountCreatureID[1]"] > 0).astype(int)
JJTaxiNodes = JJTaxiNodes.rename(columns={"MountCreatureID[0]": "H", "MountCreatureID[1]": "A"})

JJTaxiNodes.to_csv("JJTaxiNodes.csv", index=True)

### Process TaxiPath (for directions feature)
TaxiPath = pd.read_csv("TaxiPath.csv", usecols=["ID", "FromTaxiNode", "ToTaxiNode"])

TaxiNode_merge = JJTaxiNodes.copy()
TaxiNode_merge.columns = JJTaxiNodes.columns.map(lambda x: str(x) + '_from')
TaxiPath_calc = (TaxiPath.merge(TaxiNode_merge, how="inner", left_on="FromTaxiNode", right_index=True)
                        .drop(columns=["Name_lang_from", "ContinentID_from", "A_from", "H_from"]))

TaxiNode_merge = JJTaxiNodes.copy()
TaxiNode_merge.columns = JJTaxiNodes.columns.map(lambda x: str(x) + '_to')
TaxiPath_calc = (TaxiPath_calc.merge(TaxiNode_merge, how="inner", left_on="ToTaxiNode", right_index=True)
                        .drop(columns=["Name_lang_to", "ContinentID_to", "A_to", "H_to"]))

def distance(x1, y1, x2, y2):
    return ((x2-x1)**2 + (y2-y1)**2)**0.5

TaxiPath_calc["Distance"] = distance(TaxiPath_calc["Pos[0]_from"], TaxiPath_calc["Pos[1]_from"], TaxiPath_calc["Pos[0]_to"], TaxiPath_calc["Pos[1]_to"])
TaxiPath_calc = (TaxiPath_calc.round({"Distance": 0})
                                .drop(columns=["ID", "Pos[0]_from", "Pos[1]_from", "Pos[0]_to", "Pos[1]_to"]))

TaxiPath_calc.to_csv("JJTaxiPath.csv", index=False)

### Process portals (for directions feature)
# To save on space, we will join WaypointEdge with WaypointNode in the addon and not here,
# since we need them separately anyway during the walking/cross-join part

# WaypointNode: Portal entrances and exits
WaypointNode = pd.read_csv("WaypointNode.csv", usecols=["ID", "Name_lang", "SafeLocID", "Field_8_2_0_30080_005"])
# WaypointSafeLocs: Locations of portals
WaypointSafeLocs = pd.read_csv("WaypointSafeLocs.csv").drop(columns="Pos[2]")

WaypointNode_Loc = (pd.merge(WaypointNode, WaypointSafeLocs,
                            how="inner", # exclude portals that don't have a set location (e.g. mage portals)
                            left_on="SafeLocID",
                            right_on="ID",
                            suffixes=["", "_WSL"])
                        .drop(columns=["ID_WSL", "SafeLocID"])
                        .rename(columns={"Field_8_2_0_30080_005": "Type"}))
WaypointNode_Loc.to_csv("JJWaypointNode.csv", index=False)

# WaypointEdge: Portal connections
WaypointEdge = pd.read_csv("WaypointEdge.csv", usecols=["Start", "End", "PlayerConditionID"])

# remove edges that involve start or end points not in the WaypointNode_Loc table (removes mage portal edges etc.)
WaypointEdgeReduced = WaypointEdge[WaypointEdge.Start.isin(WaypointNode_Loc.ID) & WaypointEdge.End.isin(WaypointNode_Loc.ID)]
WaypointEdgeReduced.to_csv("JJWaypointEdge.csv", index=False)

# PlayerCondition: Prerequisites for using a portal connection/taxi node/etc. Keep this separate from the WaypointEdge because otherwise
# there would be a lot of duplicate data
PlayerCondition = pd.read_csv("PlayerCondition.csv", usecols=["ID", "RaceMask"])
PlayerCondition_edgeonly = PlayerCondition[PlayerCondition.ID.isin(WaypointEdge.PlayerConditionID)]

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
    .to_csv("JJPlayerCondition.csv", index=False))