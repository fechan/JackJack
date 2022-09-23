#!/usr/bin/python3

from zipfile import ZipFile, ZIP_DEFLATED
import os

# get all files in TOC
with open("JackJack.toc") as tocfile:
    toc = [line.strip().replace("\\", "/") for line in tocfile.readlines() if not (line.strip() == "" or line.startswith("#"))]

# get version string
with open("JackJack.toc") as tocfile:
    version = [line.strip() for line in tocfile.readlines() if line.startswith("## Version:")][0]
    version = version.replace("## Version: ", "")

with ZipFile(os.path.join("Releases", version + ".zip"), "w", ZIP_DEFLATED) as jjzip:
    for file in toc:
        jjzip.write(file)