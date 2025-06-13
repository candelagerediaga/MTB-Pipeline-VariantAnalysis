#!/bin/bash

# directory (introduced with a parameter)
  directory="$1" # Asign the parameter to a variable
 
  # Verify if the parameter has been introduced
  if [ -z "$1" ]; then
    echo "Please, introduce a valid directory path to your analysis folder (for example: /home/user)."
    exit 1
  fi

  echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tThe directory provided is $directory, it will be used for further analysis."

# Create Raw_Data folder and move all the samples into it
  mkdir -p "$directory/Raw_Data"
  echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tAll the initial samples will be stored in Raw_Data folder, located in $directory."

# Create Analysis folder to unify results of analyzes
  mkdir -p "$directory/Analysis"
  echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tAll the results will be stored Analysis folder, located in $directory.\n"

# Check if the directory has samples, and check if the samples already exist in Raw_Data folder and results in Analysis folder
  # If they already exist, skip them. If they are new, move them into Raw_Data
 
  source check_samples.sh


echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tStarting Quality Control..."

# FastQC
  echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tStarting FastQC...\n"

  source FastQC.sh

  echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tFastQC finished!\n"

# fastp
  echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')\tStarting fastp...\n"

  source fastp.sh 

  echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tfastp finished!\n"

# MultiQC
  if [ "$new_samples" -eq 1 ]; then
    echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tJoining FastQC and fastp reports with MultiQC. Results will be placed in Analysis folder!"
    
    container_name="multiqc_container"
    docker run --user root -d -v "$directory/Analysis/:/data" --name $container_name quay.io/biocontainers/multiqc:1.27.1--pyhdfd78af_0 sh -c "cd /data ; multiqc ."
    source capture_stats.sh $directory $container_name

  else 
    echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tThere aren't new samples to analyse. MultiQC will not be executed."
  fi

echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tQuality Control finished!"

# Select program to run after
  echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tFor variant analysis of the samples, you can carry out MTBseq, Snippy or TBprofiler."
  echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tYou can chose to run only one, two, or the three of them.\n"

  ./select_option.sh "" $directory
