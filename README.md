# JackJack
Adds TomTom waypoints based on location name. Locations and their coordinates are based on data from [WoW.tools](https://wow.tools/).

Don't know where Kalimgrimmardrassil is? Now you don't have to waste time searching on Google where everything is and just add a waypoint directly there!

![image](https://user-images.githubusercontent.com/56131910/202392891-05155258-6e1f-4ed8-8263-ad8cf7f931bf.png)

![image](https://user-images.githubusercontent.com/56131910/202392818-c1f395a7-9f4d-4d22-9a57-ad2e1fce9754.png)

## Download and install
### With Wowup
Wowup is preferred because it will auto-update when new versions are uploaded. Search JackJack in the "Get Addons" tab and install it from there.

If it doesn't show up there, in the "Get Addons" tab, click "Install from URL" in the top right, paste in `https://github.com/fechan/JackJack/`, click "Import", then "Install". This method is preferred since Wowup can automatically detect updates from this repo's releases.

### Manually
Check the [releases page](https://github.com/fechan/JackJack/releases) for the zip file. Unzip to a new folder called JackJack in your addons directory and enable JackJack in your in-game addons menu. You will have to check the releases page periodically and manually install again for updates.

## Requirements
This addon uses TomTom to add waypoints to the map. https://www.curseforge.com/wow/addons/tomtom

## Features
### Set a waypoint at a location
Open the map to show JackJack and type a location (like "orgrimmar") into the search box

Then select one of the locations to add it as a TomTom waypoint.

![JackJack GIF demo](https://user-images.githubusercontent.com/56131910/158125400-dd507318-5fa8-4fd2-af0a-ea8a9a09f8d5.gif)

### Get directions to a location (experimental)
You can get directions from your player to a location by typing a location into the search box, then clicking the directions icon button to the right of the location. This will add each step of the directions as a TomTom waypoint and show a list of directions in the main window.

This is an experimental feature, meaning it might be wrong. For example, it might lead you to portals you haven't unlocked yet, or which are temporary during a quest. This will probably change as I update the addon.

![Directions list](https://user-images.githubusercontent.com/56131910/191909189-17fe210e-9f45-4de1-bfc8-cc579c88960c.png)

### Commands
- `/jackjack` and `/jj` will open/close the JackJack window
- `/jjsearch <location>`  will return a list of the first 8 matching locations. For example, `/jjsearch orgrimmar` shows the following:

![image](https://user-images.githubusercontent.com/56131910/202388526-69f0c744-57fe-4589-aec3-06e0c06f8966.png)
- `/jjset <number>` will add a TomTom waypoint to the location with that number in your last jjsearch. So if you did `/jjsearch org` and Orgrimmar was the first result, then `/jjset 1` will set a waypoint for Orgrimmar

## Current datasets used
* AreaPOI - Points of Interest
* TaxiNodes - Flight points
* Map - Continent names
* AreaTable - Zone names
* WaypointNode - Portal entrances/exits
* WaypointSafeLocs - Locations of portals
* WaypointEdge - Connections between portals
* PlayerCondition - Requirements for entering portals
* ChrRaces - Player races

## Misc
This addon is named JackJack after my WoW player friend Jack because we have a mututal friend named Tom, and this addon requires TomTom.
