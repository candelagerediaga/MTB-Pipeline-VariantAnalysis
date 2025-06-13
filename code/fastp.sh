#!/bin/bash

directory=/home/cgerediaga
# Define log file and redirect script output (both stdout and stderr) to log file
log_file="$directory/Analysis/fastp_$(date '+%Y-%m-%d')_.log"
exec > >(tee -a "$log_file") 2>&1

# Create a .txt file to store names of the samples
echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tCreating sample_names.txt with the names of the samples that will be processed. Stored in Raw_Data.\n"
output_file="$directory/Raw_Data/sample_names.txt"
echo -e "Sample\tR1\tR2" > "$output_file"

# Go through all .fastq.gz files in the directory to create the .txt file with sample names and to be able to run fastp
for sample in "$directory"/Raw_Data/*.fastq.gz; do
  	# Verify if the file exists
  	if gzip -t "$sample" &> /dev/null; then

		# Name input and output files, considering that samples with R1 and R2 will be input1 and input2, and samples with only R1 or only R2 will be input
        sample_WoExtension=$(basename "$sample" .fastq.gz) # Name of the file without extension nor path of the directory
		name_sample=$(echo "$sample_WoExtension" | sed -E 's/_(R1|R2)//') # Name of the file without extension, nor path of the directory, nor _R1 or _R2

		# Match the file with its sample in .txt file
		if [[ "$sample_WoExtension" == *"_R1"* ]]; then
			echo -e "$name_sample\t$sample_WoExtension\t" >> "$output_file"
		elif [[ "$sample_WoExtension" == *"_R2"* ]]; then
		
			# Search the line corresponding to the sample and add file _R2
			if grep -q "^$name_sample" "$output_file"; then
				awk -v sample="$name_sample" -v file="$sample_WoExtension" 'BEGIN{FS=OFS="\t"} $1==sample{$3=file}1' "$output_file" > temp && mv temp "$output_file"
			else
				echo -e "$name_sample\t\t$sample_WoExtension" >> "$output_file"
			fi
		fi
	else
    	echo -e "<ERROR>:\t.gz files were not found in the directory. Check the path or the format of the files."
        exit 1
	fi
done

# Read .txt file, asign input1-output1, input2-output2 and input-output names, and run docker container in the corresponding way
echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tProcessing started..."

while IFS=$'\t' read -r sample R1 R2; do
	if [[ "$sample" == "Sample" ]]; then
		continue
	fi

	# PAIRED ENDS
	if [[ -n "$R1" && -n "$R2" ]]; then
		# Variables
		input1="$R1.fastq.gz"
		input2="$R2.fastq.gz"
		output1="output_${R1}.fastq.gz"
		output2="output_${R2}.fastq.gz"
		outputJSON="${sample}_fastp.json" # Report name without _R1 and _R2, both have been used
		outputHTML="${sample}_fastp.html" # Report name without _R1 and _R2, both have been used

		# Run docker bin with conditions
		if [ -d "$directory/Analysis/$output1" ] || [ -f "$directory/Analysis/$output2" ] || [ -f "$directory/Analysis/$outputJSON" ] || [ -f "$directory/Analysis/$outputHTML" ]; then
			echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tSample $(basename "$sample") has been already processed. Skipping it..."
			new_samples=0
			continue
    	fi

		if [ ! -f "$directory/Analysis/$output1" ] || [ ! -f "$directory/Analysis/$output2" ] || [ ! -f "$directory/Analysis/$outputJSON" ] || [ ! -f "$directory/Analysis/$outputHTML" ]; then
			echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tNew sample! Processing $sample..."	
			echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tPaired Ends found for $sample!"
			echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tExecuting fastp for sample $sample using input1=$R1.fastq.gz and input2=$R2.fastq.gz"
			
			container_name="fastp_container"
			docker run -d -v "$directory/:/data" --name $container_name quay.io/biocontainers/fastp:0.24.0--heae3180_1 sh -c "cd data/Raw_Data; fastp -i $input1 -I $input2 -o $output1 -O $output2 -q 20 --json $outputJSON --html $outputHTML"
			source capture_stats.sh $directory $container_name $sample

			# Move output files to Analysis folder
			echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tSample $sample processed. Moving output files..."
			mv "$directory/Raw_Data/$output1" "$directory/Analysis/"
			mv "$directory/Raw_Data/$output2" "$directory/Analysis/"
			mv "$directory/Raw_Data/$outputJSON" "$directory/Analysis/"
			mv "$directory/Raw_Data/$outputHTML" "$directory/Analysis/"

			# Verify if output1 has been moved correctly
			if [ -e "$directory/Analysis/$output1" ]; then
				echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tFile $output1 has been successfully moved to Analysis folder!"

				new_output1="${R1}.fastq.gz" # Rename the output to follow the structure in MTBseq
				mv "$directory/Analysis/$output1" "$directory/Analysis/$new_output1"
				echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\t$output1 has been renamed to $new_output1 to fulfill the structure of MTBseq."
			else
				echo -e "<ERROR>\tThere was a problem moving file $output1."
			fi

			# Verify if output2 has been moved correctly
			if [ -e "$directory/Analysis/$output2" ]; then
				echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tFile $output2 has been successfully moved to Analysis folder!"

				new_output2="${R2}.fastq.gz" # Rename the output to follow the structure in MTBseq
				mv "$directory/Analysis/$output2" "$directory/Analysis/$new_output2"
				echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\t$output2 has been renamed to $new_output2 to fulfill the structure of MTBseq."
			else
				echo -e "<ERROR>\tThere was a problem moving file $output2."
			fi

			# Verify if outputJSON has been moved correctly
			if [ -e "$directory/Analysis/$outputJSON" ]; then
				echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tFile $outputJSON has been successfully moved to Analysis folder!"
			else
				echo -e "<ERROR>\tThere was a problem moving file $outputJSON."
			fi

			# Verify if outputHTML has been moved correctly
			if [ -e "$directory/Analysis/$outputHTML" ]; then
				echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tFile $outputHTML has been successfully moved to Analysis folder!"
			else
				echo -e "<ERROR>\tThere was a problem moving file $outputHTML."
			fi
		fi
	
	# SINGLE ENDS WITH R1
	elif [[ -n "$R1" ]]; then 
		# Variables
		input="$R1.fastq.gz"
		output="output_${R1}.fastq.gz"
		outputJSON="${R1}_fastp.json" # Name with sample_R1
		outputHTML="${R1}_fastp.html" # Name with sample_R1

		# Run docker bin with conditions
		if [ -f "$directory/Analysis/$output" ] || [ -f "$directory/Analysis/$outputJSON" ] || [ -f "$directory/Analysis/$outputHTML" ]; then
			echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tSample $(basename "$sample") has been already processed. Skipping it..."
			new_samples=0
			continue
    	fi
		
		if [ ! -f "$directory/Analysis/$output" ] ||  [ ! -f "$directory/Analysis/$outputJSON" ] || [ ! -f "$directory/Analysis/$outputHTML" ]; then
			echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tNew sample! Processing $sample..."	
			echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tSingle End R1 found for $sample!"
			echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tExecuting fastp for sample $sample using input=$R1.fastq.gz"
			
			container_name="fastp_container"
			docker run -d -v "$directory/:/data" --name $container_name quay.io/biocontainers/fastp:0.24.0--heae3180_1 sh -c "cd data/Raw_Data; fastp -i $input -o $output -q 20 --json $outputJSON --html $outputHTML"
			source capture_stats.sh $directory $container_name $sample

			# Move output files to fastp folder
			echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tSample $sample processed. Moving output files..."
			mv "$directory/Raw_Data/$output" "$directory/Analysis/"
			mv "$directory/Raw_Data/$outputJSON" "$directory/Analysis/"
			mv "$directory/Raw_Data/$outputHTML" "$directory/Analysis/"

			# Verify if output has been moved correctly
			if [ -e "$directory/Analysis/$output" ]; then
				echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tFile $output has been successfully moved to Analysis folder!"
			
				new_output="${R1}.fastq.gz" # Rename the output to follow the structure in MTBseq
				mv "$directory/Analysis/$output" "$directory/Analysis/$new_output"
				echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\t$output has been renamed to $new_output to fulfill the structure of MTBseq."
			else
				echo -e "<ERROR>\tThere was a problem moving file $output."
			fi

			# Verify if outputJSON has been moved correctly
			if [ -e "$directory/Analysis/$outputJSON" ]; then
				echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tFile $outputJSON has been successfully moved to Analysis folder!"
			else
				echo -e "<ERROR>\tThere was a problem moving file $outputJSON."
			fi

			# Verify if outputHTML has been moved correctly
			if [ -e "$directory/Analysis/$outputHTML" ]; then
				echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tFile $outputHTML has been successfully moved to Analysis folder!\n"
			else
				echo -e "<ERROR>\tThere was a problem moving file $outputHTML.\n"
			fi
		fi

	# SINGLE ENDS WITH R2
	elif [[ -n "$R2" ]]; then 
		# Variables
		input="$R2.fastq.gz"
		output="output_${R2}.fastq.gz"
		outputJSON="${R2}_fastp.json" # Name with sample_R2
		outputHTML="${R2}_fastp.html" # Name with sample_R2

		# Run docker bin with conditions
		if [ -f "$directory/Analysis/$output" ] || [ -f "$directory/Analysis/$outputJSON" ] || [ -f "$directory/Analysis/$outputHTML" ]; then
			echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tSample $(basename "$sample") has been already processed. Skipping it..."
			new_samples=0
			continue
    	fi
			
		if [ ! -f "$directory/Analysis/$output" ] ||  [ ! -f "$directory/Analysis/$outputJSON" ] || [ ! -f "$directory/Analysis/$outputHTML" ]; then
			echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tNew sample! Processing $sample..."	
			echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tSingle End R2 found for $sample!"
			echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tExecuting fastp for sample $sample using input=$R2.fastq.gz"
			
			container_name="fastp_container"
			docker run -d -v "$directory/:/data" --name $container_name quay.io/biocontainers/fastp:0.24.0--heae3180_1 sh -c "cd data/Raw_Data; fastp -i $input -o $output -q 20 --json $outputJSON --html $outputHTML"
			source capture_stats.sh $directory $container_name $sample

			# Move output files to fastp folder
			echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tSample $sample processed. Moving output files..."
			mv "$directory/Raw_Data/$output" "$directory/Analysis/"
			mv "$directory/Raw_Data/$outputJSON" "$directory/Analysis/"
			mv "$directory/Raw_Data/$outputHTML" "$directory/Analysis/"

			# Verify if output has been moved correctly
			if [ -e "$directory/Analysis/$output" ]; then
				echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tFile $output has been successfully moved to Analysis folder!"
			
				new_output="${R1}.fastq.gz" # Rename the output to follow the structure in MTBseq
				mv "$directory/Analysis/$output" "$directory/Analysis/$new_output"
				echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\t$output has been renamed to $new_output to fulfill the structure of MTBseq."
			else
				echo -e "<ERROR>\tThere was a problem moving file $output."
			fi

			# Verify if outputJSON has been moved correctly
			if [ -e "$directory/Analysis/$outputJSON" ]; then
				echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tFile $outputJSON has been successfully moved to Analysis folder!"
			else
				echo -e "<ERROR>\tThere was a problem moving file $outputJSON."
			fi

			# Verify if outputHTML has been moved correctly
			if [ -e "$directory/Analysis/$outputHTML" ]; then
				echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tFile $outputHTML has been successfully moved to Analysis folder!\n"
			else
				echo -e "<ERROR>\tThere was a problem moving file $outputHTML.\n"
			fi
		fi
	fi
done < "$output_file"

# Close redirection to .log to avoid obtaining data from following scripts
exec > /dev/tty 2>&1
