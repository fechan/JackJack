# Package the addon as a zip file, excluding the DataProcessing directory, hidden files/folders, and itself
# run this in the parent folder of the JackJack repo!
zip -r "JackJack/JackJack.zip"\
    "JackJack/fzy_lua.lua"\
    "JackJack/JackJackLocations.lua"\
    "JackJack/WaypointNodeWithLocation.lua"\
    "JackJack/WaypointEdgeReduced.lua"\
    "JackJack/PlayerConditionExpanded.lua"\
    "JackJack/JackJackDirections.lua"\
    "JackJack/JackJackUI.lua"\
    "JackJack/JackJack.lua"\
    "JackJack/directions.blp"\
    "JackJack/JackJack.toc"