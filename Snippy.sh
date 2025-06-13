#!/bin/bash

# Define log file and redirect script output (both stdout and stderr) to log file
log_file="$directory/Analysis/snippy_$(date '+%Y-%m-%d')_.log"
exec > >(tee -a "$log_file") 2>&1

complete_reference=$(ls "$directory"/*.gbk | head -n 1)
reference=$(basename "$complete_reference") 

# Go through all the files .fastq.gz in the directory to be able to run Snippy
# Samples must be read from the file created before, in order to find samples with paired ends. 
echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tThe reference file for the analysis is $reference."

output_file="$directory/Raw_Data/sample_names.txt"
while IFS=$'\t' read -r sample R1 R2; do

	if [[ "$sample" == "Sample" ]]; then
		continue
	fi

	if [[ -n "$R1" && -n "$R2" ]]; then
		# Variables
		input1="$R1.fastq.gz"
		input2="$R2.fastq.gz"
	

		# Run docker bin with conditions
		if [ -d "$directory/Analysis/mysnps_$sample" ]; then
			echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tThe folder mysnps_$sample already exists, skipping sample $sample..."
			continue
		fi
		
		if [ ! -d "$directory/Analysis/mysnips_$sample" ]; then
			echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tStarting Snippy analysis for sample $sample."
			echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tThe inputs for the analysis are $input1 and $input2."
			echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tResults will be stored in mysnips_$sample folder, located in $directory/Analysis."
			
			cp $directory/$reference "$directory/Analysis/refe.gbk"
			
			container_name="snippy_container"
			docker run -d -v "$directory/:/data" --name $container_name quay.io/biocontainers/snippy:4.6.0--hdfd78af_5 sh -c "cd data/Analysis; snippy --mincov 4 --minfrac 0.75 --minqual 20 --cpus 16 --outdir mysnps_$sample --report --ref refe.gbk --R1 $input1 --R2 $input2"
			source capture_stats.sh $directory $container_name $sample
		fi

	else
		echo -e "\n<ERROR>\t.gz files were not found in the directory. Check the path or the format of the files."
		exit 1
	fi
done < "$output_file"

# Create input.tab for running snippy-multi
	input_txt="$directory/Raw_Data/sample_names.txt"
	output_tab="$directory/Analysis/input.tab"

	# Create the header of the output file
	echo -e "# input.tab = ID R1 [R2]" > "$output_tab"

	# Read sample_names.txt file and complete the information
	tail -n +2 "$input_txt" | while IFS=$'\t' read -r sample r1 r2; do
		r1_path="/data/Analysis/${r1}.fastq.gz"
		r2_path="/data/Analysis/${r2}.fastq.gz"
		echo -e "${sample}\t${r1_path}\t${r2_path}" >> "$output_tab"
	done

# Run snippy-multi
	echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tRunning snippy-multi. Results of each sample will be stored in a folder with its name, located in $directory/Analysis."
	container_name="snippy_container"
	step="snippy_multi"
	docker run -d -v "$directory:/data" --name $container_name quay.io/biocontainers/snippy:4.6.0--hdfd78af_5 sh -c "cd data/Analysis && snippy-multi input.tab --ref refe.gbk --mincov 4 --minfrac 0.75 --minqual 20 --cpus 16 > run_snippy.sh && bash run_snippy.sh"
	source capture_stats.sh $directory $container_name $step

# Run snp-dists
	echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tRunning snp-dists. The distance matrix obtained will be stored in $directort/Analysis."
	container_name="snippy_container"
	step="snp-dists"
	docker run -d -v "$directory:/data" --name $container_name staphb/snp-dists:latest sh -c 'cd /data/Analysis && snp-dists -b core.full.aln > snp-distances_snippy.tsv'
	source capture_stats.sh $directory $container_name $step

# Close redirection to .log to avoid obtaining data from following scripts
exec > /dev/tty 2>&1