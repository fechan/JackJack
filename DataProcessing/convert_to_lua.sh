#!/usr/bin/bash

cd processed-csv-data

# if keeping IDs is important, then luaDict
node ../csv-to-lua/Converter.js JJAreaPOI.csv luaArray
mv -f JJAreaPOI.lua ../../Data

node ../csv-to-lua/Converter.js JJMap.csv luaDict
mv -f JJMap.lua ../../Data

node ../csv-to-lua/Converter.js JJPlayerCondition.csv luaDict
mv -f JJPlayerCondition.lua ../../Data

node ../csv-to-lua/Converter.js JJTaxiNodes.csv luaDict
mv -f JJTaxiNodes.lua ../../Data

node ../csv-to-lua/Converter.js JJTaxiPath.csv luaArray
mv -f JJTaxiPath.lua ../../Data

node ../csv-to-lua/Converter.js JJWaypointEdge.csv luaArray
mv -f JJWaypointEdge.lua ../../Data

node ../csv-to-lua/Converter.js JJWaypointNode.csv luaDict
mv -f JJWaypointNode.lua ../../Data