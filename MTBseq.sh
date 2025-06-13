#!/bin/bash

# Define log file and redirect script output (both stdout and stderr) to log file
log_file="$directory/Analysis/mtbseqq_$(date '+%Y-%m-%d')_.log"
exec > >(tee -a "$log_file") 2>&1

# Check if the samples have the correct structure name
# Go through all the files .fastq.gz in the directory to be able to run MTBseq
regex="^[^_]+_[^_]+_(R1|R2)\.fastq\.gz$" # Structure needed for the file names

echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tChecking the structure of the samples:"

for sample in "$directory"/Analysis/*.fastq.gz; do
  # Verify if the file exists
  if gzip -t "$sample" &> /dev/null; then

    # Check if input files have he correct structure to be able to run MTBseq
    sample=$(basename "$sample") # Name of the file without path of the directory
    if [[ "$sample" =~ $regex ]]; then
      echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tFile $sample follows the structure."
    else
      echo -e "<ERROR>\tThe structure of the file name $sample is not correct. It should follow this structure: [SampleID]_[LibID]_[Direction].fastq.gz. Please check before continuing."
      exit 1
    fi
  else
    echo -e "<ERROR>\t.gz files were not found in the directory. Check the path or the format"
    exit 1
  fi
done

# Create samples.txt file, necessary for steps TBvariants, TBjoin, TBamend and TBgroups
input_file="$directory/Raw_Data/sample_names.txt"
output_file="$directory/Analysis/samples.txt"

# Create output file
> "$output_file"

# Read input file and process each line
while IFS=$'\t' read -r sample r1 r2; do
  # Obtain the information of the sample which is useful, SampleID and LibID
  part1=$(echo "$sample" | cut -d'_' -f1)
  part2=$(echo "$sample" | cut -d'_' -f2)

  # Write the modified line in output file
  echo -e "$part1\t$part2" >> "$output_file"
done < <(tail -n +2 "$input_file") # Ignore the first line of input file (header)

# Run docker container
echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tStarting MTBseq steps..."

# --step TBbwa
  echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tStep TBbwa:"
  
  container_name="mtbseq_container"
  step="TBbwa"
  docker run -d -v "/$directory:/data" --name $container_name quay.io/biocontainers/mtbseq:1.1.0--hdfd78af_0 sh -c "cd data/Analysis/ ; MTBseq --step TBbwa --threads 16"
  source capture_stats.sh $directory $container_name $step
  
# --step TBrefine
  echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tStep TBbrefine:"
  
  container_name="mtbseq_container"
  step="TBrefine"
  docker run -d -v "/$directory:/data" --name $container_name quay.io/biocontainers/mtbseq:1.1.0--hdfd78af_0 sh -c "cd data/Analysis/ ; MTBseq --step TBrefine --threads 16"
  source capture_stats.sh $directory $container_name $step

# --step TBpile
  echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tStep TBpile:"
  
  container_name="mtbseq_container"
  step="TBpile"
  docker run -d -v "/$directory:/data" --name $container_name quay.io/biocontainers/mtbseq:1.1.0--hdfd78af_0 sh -c "cd data/Analysis/ ; MTBseq --step TBpile --threads 16"
  source capture_stats.sh $directory $container_name $step

# --step TBlist
  echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tStep TBlist:"
  
  container_name="mtbseq_container"
  step="TBlist"
  docker run -d -v "/$directory:/data" --name $container_name quay.io/biocontainers/mtbseq:1.1.0--hdfd78af_0 sh -c "cd data/Analysis/ ; MTBseq --step TBlist --threads 16"
  source capture_stats.sh $directory $container_name $step

# --step TBvariants (diferencias --snp_vars)
  echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tStep TBvariants:"
  
  container_name="mtbseq_container"
  step="TBvariants"
  docker run -d -v "/$directory:/data" --name $container_name quay.io/biocontainers/mtbseq:1.1.0--hdfd78af_0 sh -c "cd data/Analysis/ ; MTBseq --step TBvariants --samples samples.txt --mincovf 4 -- mincovr 4 --minphred20 4 --minfreq 75 --threads 16"
  source capture_stats.sh $directory $container_name $step

# --step TBstats
  echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tStep TBstats:"
  
  container_name="mtbseq_container"
  step="TBstats"
  docker run -d -v "/$directory:/data" --name $container_name quay.io/biocontainers/mtbseq:1.1.0--hdfd78af_0 sh -c "cd data/Analysis/ ; MTBseq --step TBstats --threads 16"
  source capture_stats.sh $directory $container_name $step

# Filter the results from Statistics/Mapping_and_Variant_Statistics.tab
  # We are going to filter the columns [(Any) Coverage mean] and [(Any) Coverage median] with values bigger than the ones introduced by the user
  # With this filtered data, we will create samples2.txt

  echo -e "\nDo you want to filter the statistics created? (y/n)"
  read -r answer
  if [[ "$answer" != "y" && "$answer" != "n" ]]; then
    echo -e "<ERROR>\tInvalid input. Please enter 'y' or 'n'."
    read -r answer
  fi
  if [[ "$answer" == "y" || "$answer" == "n" ]]; then
    if [[ "$answer" == "y" ]]; then      
      while true; do
        echo -e "==> Insert a Coverage mean value."
        read -r cov_mean
        if [[ "$cov_mean" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
          coverage_mean="$cov_mean"
          break
        else
          echo -e "<ERROR>\tInvalid input. Please enter a numeric value."
        fi
      done

      # Pedir Coverage median
      while true; do
        echo -e "==> Insert a Coverage median value."
        read -r cov_median
        if [[ "$cov_median" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
          coverage_median="$cov_median"
          break
        else
          echo -e "<ERROR>\tInvalid input. Please enter a numeric value."
        fi
      done

      echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tFiltering Statistics/Mapping_and_Variant_Statistics.tab." 
      echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tSamples with (Any) Coverage mean below $coverage_mean and (Any) Coverage median below $coverage_median will be filtered."
      python3 filterTab.py $directory $coverage_mean $coverage_median
    fi

    if [[ "$answer" == "n" ]]; then
      echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tSkipping filtering of Statistics/Mapping_and_Variant_Statistics.tab..."
    fi
  fi  

# --step TBstrains
  echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tStep TBb strains:"
 
  container_name="mtbseq_container"
  step="TBstrains"
  docker run -d -v "/$directory:/data" --name $container_name quay.io/biocontainers/mtbseq:1.1.0--hdfd78af_0 sh -c "cd data/Analysis/ ; MTBseq --step TBstrains --mincovf 4 -- mincovr 4 --minphred20 4 --minfreq 75 --threads 16"
  source capture_stats.sh $directory $container_name $step

# --step TBjoin (diferencias --snp-vars)
  echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tStep TBjoin:"
  
  container_name="mtbseq_container"
  step="TBjoin"
  docker run -d -v "/$directory:/data" --name $container_name quay.io/biocontainers/mtbseq:1.1.0--hdfd78af_0 sh -c "cd data/Analysis/ ; MTBseq --step TBjoin --samples samples.txt --project GenomicAnalysis --mincovf 4 -- mincovr 4 --minphred20 4 --minfreq 75 --threads 16"
  source capture_stats.sh $directory $container_name $step

# --step TBamend
  echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tStep TBamend:"
  
  container_name="mtbseq_container"
  step="TBamend"
  docker run -d -v "/$directory:/data" --name $container_name quay.io/biocontainers/mtbseq:1.1.0--hdfd78af_0 sh -c "cd data/Analysis/ ; MTBseq --step TBamend --samples samples.txt --project GenomicAnalysis --mincovf 4 -- mincovr 4 --minphred20 4 --minfreq 75 --threads 16"
  source capture_stats.sh $directory $container_name $step

# --step TBgroups
  echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tStep TBgroups:"
  
  container_name="mtbseq_container"
  step="TBgroups"
  docker run -d -v "/$directory:/data" --name $container_name quay.io/biocontainers/mtbseq:1.1.0--hdfd78af_0 sh -c "cd data/Analysis/ ; MTBseq --step TBgroups --samples samples.txt --project GenomicAnalysis --distance 12  --threads 16"
  source capture_stats.sh $directory $container_name $step

# Close redirection to .log to avoid obtaining data from following scripts
exec > /dev/tty 2>&1