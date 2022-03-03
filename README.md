# JackJack
Adds TomTom waypoints based on location name (e.g. `/jackjack orgrimmar`). Locations and their coordinates are based on data from [WoW.tools](https://wow.tools/).

Don't know where Kalimgrimmardrassil is? Now you don't have to waste time searching on Google where everything is and just add a waypoint directly there!

## Download and install
### With Wowup
In the "Get Addons" tab, click "Install from URL" in the top right, paste in `https://github.com/fechan/JackJack/`, click "Import", then "Install". This method is preferred since Wowup can automatically detect updates from this repo's releases.

### Manually
Check the [releases page](https://github.com/fechan/JackJack/releases) for the zip file. Unzip to a new folder called JackJack in your addons directory and enable JackJack in your in-game addons menu.

## Requirements
This addon uses TomTom to add waypoints to the map. https://www.curseforge.com/wow/addons/tomtom

## Example usage
Typing `/jackjack orgrimmar` or `/jj orgrimmar` will show the following menu. Click a button to add the corresponding TomTom waypoint to your map.

![Screenshot of JackJack](https://user-images.githubusercontent.com/56131910/155943487-ca33dac0-37dc-42e3-ae7d-ee2d3b1c4b36.png)

## Current datasets used
* AreaPOI - Points of Interest
* WaypointNode - Portal exits
* TaxiNodes - Flight points
* Map - Continent names (provides foreign keys only)
* AreaTable - Zone names (provides foreign keys only)

## Misc
This addon is named JackJack after my WoW player friend Jack because we have a mututal friend named Tom, and this addon requires TomTom.
