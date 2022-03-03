# Get all the CSVs from WoW.tools with wget, because pandas.read_csv runs into HTTP 403 for some reason
BUILD="9.2.0.42488"

for TABLE in AreaPOI WorldSafeLocs WaypointNode WaypointSafeLocs AreaTable Map TaxiNodes
do
	wget "https://wow.tools/dbc/api/export/?name=${TABLE}&build=${BUILD}" -O "${TABLE}.csv"
done
