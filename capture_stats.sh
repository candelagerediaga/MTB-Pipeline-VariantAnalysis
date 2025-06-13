#!/bin/bash

directory=$1
container_name=$2
sampleStep=$3 # Refers to each sample/step to make the output file more understandable.

# Output file for statistics
output_file="$directory/Analysis/stats_$container_name.txt"

# If the file doesn't exist, initialize it. If the file already exists (previous samples have been processed), don't overwrite it
if [ ! -f "$output_file" ]; then
    echo -e "NAME\tCPU %\tMEM USAGE / LIMIT\tMEM %\tTIME" > "$output_file"
fi

echo -e "\n$sampleStep" >> "$output_file"
echo -e "--------------------" >> "$output_file"


start_time=$(date +"%Y-%m-%d %H:%M:%S")
while [ "$(docker ps -q -f name=$container_name)" ]; do
    current_time=$(date +"%Y-%m-%d %H:%M:%S")
    if docker inspect "$container_name" &>/dev/null; then
        docker stats --no-stream --format "{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t$current_time" | grep $container_name >> "$output_file"
        docker logs $container_name
    fi
    sleep 5
done
end_time=$(date +"%Y-%m-%d %H:%M:%S")

# Add start and end times to the output file
echo -e "\n==> Start Time: $start_time" >> "$output_file"
echo -e "==> End Time: $end_time" >> "$output_file"

# Calculate total time and add it to the output file
start_seconds=$(date -d "$start_time" +%s)
end_seconds=$(date -d "$end_time" +%s)
total_time=$((end_seconds - start_seconds))
total_time_formatted=$(date -u -d @"$total_time" +"%H:%M:%S")
echo -e "==> Total Time: $total_time_formatted\n" >> "$output_file"


if docker inspect "$container_name" &>/dev/null; then
    docker rm "$container_name"
fi