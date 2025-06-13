# MTB-Pipeline-VariantAnalysis
A Docker-based pipeline for automated variant detection and quality control of Mycobacterium tuberculosis samples using MTBseq, Snippy, and TBProfiler.

## Overview

This repository provides the code and workflow for performing variant detection analysis on *Mycobacterium tuberculosis* samples. It includes nine Bash scripts and one Python script.

The workflow is designed to be executed via the main script, `main.sh`, which orchestrates the entire analysis pipeline. No additional software installation is required—only the necessary Docker images must be available.

---

## Usage

### Step 1: Start the Pipeline

Run the `main.sh` script, providing the path to the directory containing the `.fastq.gz` files:

```bash
./main.sh /path/to/samples
```

This will automatically call the `check_samples.sh` script, which performs the following:

* Verifies the presence of `.fastq.gz` files in the specified directory.
* Classifies samples as new or previously analyzed by checking the `Raw_Data` folder.
* Ensures new samples are copied to `Raw_Data` if they haven't been analyzed before.

---

### Step 2: Quality Control and Preprocessing

If new samples are detected, the following scripts are triggered:

* `FastQC.sh`: Performs quality control.
* `fastp.sh`: Executes preprocessing.

Both scripts check if output files already exist in the `Analysis` folder. If they do, the sample is skipped. After this step, if any new samples were processed, a MultiQC report is generated to summarize the quality analysis results.

---

### Step 3: Variant Detection Tool Selection

Once the quality analysis is complete, the `select_option.sh` script is launched. This provides a menu-based interface to choose one or more variant detection tools:

* **MTBseq**
* **Snippy**
* **TBProfiler**
* **All sequentially**

Usage:

```bash
./select_option -[selectedOption] /path/to/samples
```

After running a selected tool, the user may choose to run additional tools or exit the workflow. The options launch the following scripts:

* `MTBseq.sh`
* `Snippy.sh`
* `TBProfiler.sh`

---

## Tool-Specific Details

### MTBseq

* Executed step-by-step, allowing granular control.
* Each step depends on the successful execution of the previous one.
* After the `TBstats` step, the user is given the option to filter statistics using the `filterTab.py` script.
* The Docker container checks whether a sample has already been processed, and skips it if so.

### Snippy

* Runs sequentially for each sample.
* Can be automated across multiple samples using `snippy-multi`.
* `snp-dists` requires `snippy-multi` to have been executed beforehand.
* Checks if an output folder already exists in `Analysis` before processing, indicating whether the sample has been previously analyzed.

### TBProfiler

* Runs directly in a Docker container after confirming output files are not already present.
* Skips samples that have already been processed.

---

## Resource Monitoring

The `capture_stats.sh` script captures Docker container performance metrics using:

* `docker stats`: Saves resource usage (CPU, memory, etc.) to a `.txt` file named after each tool.
* `docker logs`: Captures console output and saves it to a `.log` file.

This enables detailed tracking of computational resources and execution time for each stage.

---

## Reference Data

The annotated *Mycobacterium tuberculosis* reference genome used in the Snippy analysis is included and must be present in the root directory where the pipeline is executed.

---

