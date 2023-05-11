#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 framekm_folder metadata_folder log_file_path"
    exit 1
fi

folder1="$1"
folder2="$2"
file_path="$3"
max_file_size=$((2 * 1024 * 1024))

# Remove all empty files from folder2
find "$folder2" -type f -empty -exec rm -f {} +

# Process files in folder1
find "$folder1" -type f | while read -r file; do
    base_name=$(basename "$file")
    json_file="${folder2}/${base_name}.json"
    
    if [[ ! -s "$json_file" ]]; then
        echo "Removing: $file"
        rm -f "$file"
    fi
done

# Check and truncate the file if it's larger than 2 MB
if [ -e "$file_path" ]; then
    file_size=$(stat -c%s "$file_path")
    if [ $file_size -gt $max_file_size ]; then
        tail -c $max_file_size "$file_path" > "${file_path}.tmp" && mv "${file_path}.tmp" "$file_path"
        echo "Truncated $file_path to the last 2 MB"
    fi
fi