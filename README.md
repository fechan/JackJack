# JackJack
Adds TomTom waypoints based on location name. Locations and their coordinates are based on data from [WoW.tools](https://wow.tools/).

Don't know where Kalimgrimmardrassil is? Now you don't have to waste time searching on Google where everything is and just add a waypoint directly there!

![Partial JackJack screenshot](https://user-images.githubusercontent.com/56131910/159831814-c477782b-80cb-41b9-98ee-322b1eaa5536.png)

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
You can either:
* Open the map to show JackJack and type a location (like "orgrimmar") into the search box
* Type `/jackjack orgrimmar` or `/jj orgrimmar` into the chat

Then select one of the locations to add it as a TomTom waypoint.

![JackJack GIF demo](https://user-images.githubusercontent.com/56131910/158125400-dd507318-5fa8-4fd2-af0a-ea8a9a09f8d5.gif)

### Get directions to a location (experimental)
You can get directions from your player to a location by typing a location into the search box, then clicking the directions icon button to the right of the location. This will add each step of the directions as a TomTom waypoint and print out the directions in chat.

This is an experimental feature, meaning it might be wrong. For example, it might lead you to portals you haven't unlocked yet, or which are temporary during a quest. This will probably change as I update the addon.

![Directions printout](https://user-images.githubusercontent.com/56131910/159830732-391fbc97-42bc-4cc1-8873-370f7eb260d5.png)

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
