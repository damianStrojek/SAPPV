#!/bin/bash

# Checking if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <IP> <Port>"
    exit 1
fi

IP=$1
PORT=$2

# Navigate to the specified directory
cd ./powersap/Standalone/soap || { echo "Directory not found!"; exit 1; }

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Iterating through all .xml files in the directory
for FILE in *.xml; do
    if [ -f "$FILE" ]; then
        echo -e "${GREEN}Executing command for file: $FILE${NC}"
        pwsh ./Invoke-mgmt-con-soap.ps1 $IP $PORT ./$FILE
        echo -e "${RED}--------------------------------------------------${NC}"
        echo -e ""
    else
        echo "No XML files found in the directory."
    fi
done
