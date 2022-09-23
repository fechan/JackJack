#!/usr/bin/python3

from zipfile import ZipFile, ZIP_DEFLATED

with open("JackJack.toc") as tocfile:
    toc = [line.strip().replace("\\", "/") for line in tocfile.readlines() if not (line.strip() == "" or line.startswith("#"))]

with ZipFile("JackJack.zip", "w", ZIP_DEFLATED) as jjzip:
    for file in toc:
        jjzip.write(file)