#!/bin/bash

# Get the parent folder's path
parentFolder="perimeter-paver"

mkdir $parentFolder
cp -r ./* ./$parentFolder
rm -r ./$parentFolder/releases
rm -r ./$parentFolder/resources

# Load version from info.json
jsonPath="./info.json"
if [ -f "$jsonPath" ]; then
    version=$(jq -r .version "$jsonPath")
else
    echo "Error: info.json not found or does not contain 'version' information."
    exit 1
fi

# Define the name of the zip file
zipFileName="perimeter-paver_$version.zip"

# Define the path to the output zip file
zipFilePath="./releases/$zipFileName"

# Check if the zip file already exists
if [ ! -f "$zipFilePath" ]; then
    # Create the zip file
    zip -r "$zipFilePath" "./$parentFolder"
    echo "Successfully created $zipFileName in the 'releases' subfolder."
else
    echo "Error: $zipFileName already exists in the 'releases' subfolder."
fi

rm -r "./$parentFolder"