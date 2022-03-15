# JackJack
Adds TomTom waypoints based on location name. Locations and their coordinates are based on data from [WoW.tools](https://wow.tools/).

Don't know where Kalimgrimmardrassil is? Now you don't have to waste time searching on Google where everything is and just add a waypoint directly there!

![Partial JackJack screenshot](https://user-images.githubusercontent.com/56131910/158126430-6cabc1c3-7182-42ed-ae6b-d924b8e68373.png)

## Download and install
### With Wowup
First check if JackJack appears when you search JackJack in the "Get Addons" tab and install it from there. (I'm trying to upload this to Wowinterface, from which Wowup will detect my addon)

Otherwise, in the "Get Addons" tab, click "Install from URL" in the top right, paste in `https://github.com/fechan/JackJack/`, click "Import", then "Install". This method is preferred since Wowup can automatically detect updates from this repo's releases.

### Manually
Check the [releases page](https://github.com/fechan/JackJack/releases) for the zip file. Unzip to a new folder called JackJack in your addons directory and enable JackJack in your in-game addons menu.

## Requirements
This addon uses TomTom to add waypoints to the map. https://www.curseforge.com/wow/addons/tomtom

## Example usage
You can either:
* Open the map to show JackJack and type a location (like "orgrimmar") into the search box
* Type `/jackjack orgrimmar` or `/jj orgrimmar` into the chat

Then select one of the locations to add it as a TomTom waypoint.

![JackJack GIF demo](https://user-images.githubusercontent.com/56131910/158125400-dd507318-5fa8-4fd2-af0a-ea8a9a09f8d5.gif)

## Current datasets used
* AreaPOI - Points of Interest
* TaxiNodes - Flight points
* Map - Continent names (provides foreign keys only)
* AreaTable - Zone names (provides foreign keys only)

## Misc
This addon is named JackJack after my WoW player friend Jack because we have a mututal friend named Tom, and this addon requires TomTom.
