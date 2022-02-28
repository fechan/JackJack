# Package the addon as a zip file, excluding the DataProcessing directory, hidden files/folders, and itself
# run this in the parent folder of the JackJack repo!
zip -r "JackJack/JackJack.zip" "JackJack/JackJack.toc" "JackJack/JackJack.lua" "JackJack/JackJackLocations.lua" "JackJack/fzy_lua.lua"
