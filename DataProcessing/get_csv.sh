#!/usr/bin/bash

# Get all the CSVs from WoW.tools with wget, because pandas.read_csv runs into HTTP 403 for some reason
BUILD="10.0.0.46366"

cd raw-csv-data

for TABLE in AreaPOI WaypointNode WaypointSafeLocs WaypointEdge AreaTable Map TaxiNodes TaxiPath ChrRaces PlayerCondition
do
	wget "https://wow.tools/dbc/api/export/?name=${TABLE}&build=${BUILD}" -O "${TABLE}.csv"
done
