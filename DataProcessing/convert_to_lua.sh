node ./csv-to-lua/Converter.js JackJackLocations.csv luaArray
mv -f JackJackLocations.lua ..

node ./csv-to-lua/Converter.js WaypointNodeWithLocation.csv luaDict
mv -f WaypointNodeWithLocation.lua ..

node ./csv-to-lua/Converter.js WaypointEdgeReduced.csv luaArray
mv -f WaypointEdgeReduced.lua ..

node ./csv-to-lua/Converter.js PlayerConditionExpanded.csv luaDict
mv -f PlayerConditionExpanded.lua ..