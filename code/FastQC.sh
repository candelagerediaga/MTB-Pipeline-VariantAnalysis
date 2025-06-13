#!/bin/bash

# Define log file and redirect script output (both stdout and stderr) to log file
log_file="$directory/Analysis/fastqc_$(date '+%Y-%m-%d')_.log"
exec > >(tee -a "$log_file") 2>&1

# Go through all the files .fastq.gz in the directory to be able to run FastQC
for sample in "$directory"/Raw_Data/*.fastq.gz; do
	# Verify if the files exist
	if gzip -t "$sample" &> /dev/null; then

		# Name input and output files
		sample=$(basename "$sample") # Name of the file without path of the directory
		sample_WoExtension=$(basename "$sample" .fastq.gz) # Name of the file without extension nor path of the directory
		outputHTML="${sample_WoExtension}_fastqc.html"
		outputZIP="${sample_WoExtension}_fastqc.zip"

		# Run docker bin with conditions
		if [ -f "$directory/Analysis/$outputHTML" ] || [ -f "$directory/Analysis/$outputZIP" ]; then
			echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tSample $sample has been already processed. Skipping it..."
			new_samples=0
			continue
    	fi
		
		if [ ! -f "$directory/Analysis/$outputHTML" ] || [ ! -f "$directory/Analysis/$outputZIP" ]; then
			echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tNew sample! Processing $sample..."
			
			container_name="fastqc_container"
			docker run -d -v "$directory/:/data" --name $container_name staphb/fastqc:latest sh -c "fastqc /data/Raw_Data/$sample"
			source capture_stats.sh $directory $container_name $sample

			# Move the output to Analysis folder
			mv "$directory/Raw_Data/$outputHTML" "$directory/Analysis/"
			mv "$directory/Raw_Data/$outputZIP" "$directory/Analysis/"

			# Verify if outputHTML has been moved correctly
			if [ -e "$directory/Analysis/$outputHTML" ]; then
				echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tFile $outputHTML has been successfully moved to Analysis folder!"
			else
				echo -e "<ERROR>\tThere was a problem moving file $outputHTML."
			fi

			# Verify if outputZIP has been moved correctly
			if [ -e "$directory/Analysis/$outputZIP" ]; then
				echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tFile $outputZIP has been successfully moved to Analysis folder!\n"
			else
				echo -e "<ERROR>\tThere was a problem moving file $outputZIP.\n"
			fi
		fi

	else
		echo "<ERROR>\t.gz files were not found in the directory. Check the path or the format of the files."
		exit 1
	fi
  done

# Close redirection to .log to avoid obtaining data from following scripts
exec > /dev/tty 2>&1
