# Get all the CSVs from WoW.tools with wget, because pandas.read_csv runs into HTTP 403 for some reason
BUILD="9.2.0.42979"

for TABLE in AreaPOI WaypointNode WaypointSafeLocs WaypointEdge AreaTable Map TaxiNodes TaxiPath ChrRaces PlayerCondition
do
	wget "https://wow.tools/dbc/api/export/?name=${TABLE}&build=${BUILD}" -O "${TABLE}.csv"
done
