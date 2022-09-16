# Get all the CSVs from WoW.tools with wget, because pandas.read_csv runs into HTTP 403 for some reason
BUILD="9.2.7.45338"

cd raw-csv-data

for TABLE in AreaPOI WaypointNode WaypointSafeLocs WaypointEdge AreaTable Map TaxiNodes TaxiPath ChrRaces PlayerCondition
do
	wget "https://wow.tools/dbc/api/export/?name=${TABLE}&build=${BUILD}" -O "${TABLE}.csv"
done
