node ./csv-to-lua/Converter.js ChrRacesBitmasks.csv luaDict
mv -f ChrRacesBitmasks.lua ..

node ./csv-to-lua/Converter.js WaypointNodeWithLocation.csv luaDict
mv -f WaypointNodeWithLocation.lua ..

node ./csv-to-lua/Converter.js WaypointEdgeWithRequirements.csv luaArray
mv -f WaypointEdgeWithRequirements.lua ..

node ./csv-to-lua/Converter.js JackJackLocations.csv luaArray
mv -f JackJackLocations.lua ..