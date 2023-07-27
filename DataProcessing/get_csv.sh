#!/usr/bin/bash

# Get all the CSVs from WoW.tools with wget, because pandas.read_csv runs into HTTP 403 for some reason
BUILD="10.1.5.50585"

cd raw-csv-data

for TABLE in AreaPOI WaypointNode WaypointSafeLocs WaypointEdge AreaTable Map TaxiNodes TaxiPath ChrRaces PlayerCondition
do
	OUTFILE=`echo ${TABLE} | tr '[:upper:]' '[:lower:]'`
	wget "https://wago.tools/db2/${TABLE}/csv?build=${BUILD}" -O "${OUTFILE}.csv"
done
