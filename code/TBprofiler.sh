#!/bin/bash

# Define log file and redirect script output (both stdout and stderr) to log file
log_file="$directory/Analysis/tbprofiler_$(date '+%Y-%m-%d')_.log"
exec > >(tee -a "$log_file") 2>&1

# Go through all the files .fastq.gz in the directory to be able to run TBProfiler 
# Samples must be read from the file created before, in order to find samples with paired ends. 

output_file="$directory/Raw_Data/sample_names.txt"
while IFS=$'\t' read -r sample R1 R2; do
	if [[ "$sample" == "Sample" ]]; then
		continue
	fi

	if [[ -n "$R1" && -n "$R2" ]]; then
		# Variables
		input1="$R1.fastq.gz"
		input2="$R2.fastq.gz"
		output="$sample"

		# Run docker bin with conditions
		if [ -d "$directory/Analysis/tbprofiler_results_$sample" ]; then
			echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tSample $(basename "$sample") has been already processed. Skipping it..."
			continue
		fi

		if [ ! -d "$directory/Analysis/tbprofiler_results_$sample" ]; then
			echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tStarting TBProfiler analysis for sample $sample."
			echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tThe inputs for the analysis are $input1 and $input2. The output will be $output.json and $output.csv"
			mkdir $directory/Analysis/tbprofiler_results_$sample
			echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tResults will be stored in tbprofiler_$sample folder, located in $directory/Analysis."
			
			container_name="tbprofiler_container"
			docker run -d -v "$directory/:/data" --name $container_name quay.io/staphb/tbprofiler:latest sh -c "cd Analysis; tb-profiler profile --call_whole_genome --snp_dist 12 --spoligotype -1 $input1 -2 $input2 -p $output -d tbprofiler_results_$sample --csv -t 16"
			source capture_stats.sh $directory $container_name $sample
		fi

	else
		echo -e "\n<ERROR>\t.gz files were not found in the directory. Check the path or the format of the files."
		exit 1
	fi
done < "$output_file"

# Close redirection to .log to avoid obtaining data from following scripts
exec > /dev/tty 2>&1
