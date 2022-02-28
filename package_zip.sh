# Package the addon as a zip file, excluding the DataProcessing directory, hidden files/folders, and itself
zip -r "JackJack.zip" . -x "./DataProcessing/*" ".*" "package_zip.sh"