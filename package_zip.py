#!/usr/bin/python3

from zipfile import ZipFile, ZIP_DEFLATED
import os

# get all files in TOC
with open("JackJack.toc") as tocfile:
    toc = [line.strip().replace("\\", "/") for line in tocfile.readlines() if not (line.strip() == "" or line.startswith("#") or line.startswith("Libs"))]

# get version string
with open("JackJack.toc") as tocfile:
    version = [line.strip() for line in tocfile.readlines() if line.startswith("## Version:")][0]
    version = version.replace("## Version: ", "")

def zipdir(path, ziph):
    for root, dirs, files in os.walk(path):
        for file in files:
            ziph.write(os.path.join(root, file), 
                       arcname=os.path.join(
                            "JackJack",
                            os.path.relpath(
                                os.path.join(root, file), 
                                os.path.join(path, '..')
                            )
                        )
                    )

with ZipFile(os.path.join("Releases", version + ".zip"), "w", ZIP_DEFLATED) as jjzip:
    for file in toc:
        jjzip.write(file, arcname=os.path.join("JackJack", file))
    jjzip.write("JackJack.toc", arcname=os.path.join("JackJack", "JackJack.toc"))
    jjzip.write("directions.blp", arcname=os.path.join("JackJack", "directions.blp"))
    jjzip.write("LICENSE", arcname=os.path.join("JackJack", "LICENSE"))
    zipdir("Libs", jjzip) # add the entire libs folder because some libs have their own TOC and I'm not dealing with that