#!/usr/bin/bash

# RUN THIS IN THE PROJECT ROOT
cd ./DataProcessing &&
./get_csv.sh &&
./process_csv.py &&
./convert_to_lua.sh