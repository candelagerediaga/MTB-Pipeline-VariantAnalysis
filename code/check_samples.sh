#!/bin/bash

directory="$1"

new_samples=0
  for sample in "$directory"/*.fastq.gz; do
    # Verify if the files exist
    if gzip -t "$sample" &> /dev/null; then
      # Verify if they are new
        # Name of the output files
		sample_WoExtension="$(basename "$sample".fastq.gz)"

		# Check if the sample already exists in Raw_Data.
		if [ -f "$directory/Raw_Data/$(basename "$sample")" ]; then
			echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\t$(basename "$sample") already exists in Raw_Data. Skipping it..." #Add new data or change the name of the file."
			continue
		fi
		if [ ! -f "$directory/Raw_Data/$(basename "$sample")" ]; then # If the files are not found move them to Raw_Data and continue
			echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\t$(basename "$sample") is new! Moving it to Raw_Data..."
			mv "$sample" "$directory/Raw_Data"
			new_samples=1
	fi
    else
      echo -e "<ERROR>\t.gz files were not found in the directory. Check the path or the format of the files."
      exit 1
    fi
  done

	
