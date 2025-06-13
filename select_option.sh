#!/bin/bash

date="$(date '+%Y-%m-%d %H:%M:%S')"

# echo "arguments:"$0, $1, $2
directory="$2" # Asign the parameter to a variable

# The use of the script is shown to the user
usage() {
    echo "Use: $0 [-m] [-s] [-t] [-a] /path_to_analysis_folder (for example: /home/user)"
    
    echo -e "  -m\tExecute MTBseq. Remember to check the format of the input files."
    echo -e "  -s\tExecute Snippy. Remember that you should have the reference file in your directory (.fasta or .gbk format)."
	echo -e "  -t\tExecute TBprofiler"
    echo -e "  -a\tExecute all of them (MTBseq, Snippy and TBprofiler)"
    exit 1
}

# Variables for the options
run_mtbseq=false
run_snippy=false
run_tbprofiler=false

# Verify if the parameter directory has been introduced
  if [ -z "$2" ]; then
    echo -e "<ERROR>\tSome of the parameters needed are missing, check the use and try again.\n"
    usage
  fi

# Process the option introduces
while getopts ":msta" opt; do
    case $opt in
        m)
            echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tYou have selected MTBseq."
            run_mtbseq=true
            ;;
        s)
            echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tYou have selected Snippy."
            run_snippy=true
            ;;
		t)
            echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tYou have selected TBprofiler."
            run_tbprofiler=true
            ;;
		a)
            echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tAll the tools will be executed."
            run_mtbseq=true
            run_snippy=true
			run_tbprofiler=true
            ;;
        \?)
            echo -e "-$OPTARG is not a valid option. Please select one valid option.\n" 
            usage
            ;;
    esac
done


# Verify if at least one option has been selected
if [ "$run_mtbseq" = false ] && [ "$run_snippy" = false ] && [ "$run_tbprofiler" = false ]; then
    echo -e "Select one valid option:"
	usage
fi

# Execute MTBseq if -m or -a options have been selected
if [ "$run_mtbseq" = true ]; then
    echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tStarting MTBseq...\n"

	source MTBseq.sh

	echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tMTBseq finished!\n"
fi

# Execute Snippy if -s or -a options have been selected
if [ "$run_snippy" = true ]; then
    echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tStarting Snippy...\n"

	source Snippy.sh

	echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tSnippy finished!\n"
fi

# Execute TBprofiler if -t or -a options have been selected
if [ "$run_tbprofiler" = true ]; then
    echo -e "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tStarting TBprofiler...\n"

	source TBprofiler.sh

	echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tTBprofiler finished!\n"
fi


# Function to ask the user to execute another tool (if wanted)
ask_for_another() {
    read -p "¿Do you want to execute another tool? (y/n): " choice
    if [ "$choice" = "y" ]; then
        echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tReturning to the options available...\n"
        usage
    fi
    if [ "$choice" = "n" ]; then
        echo -e "\n<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tAnalysis finished!\n"
        exit 0
    else
        echo "<INFO>\t[$(date '+%Y-%m-%d %H:%M:%S')]\tInvalid option. Please select a valid option."
        ask_for_another
    fi
}

# Ask the user to user another tool (if wanted)
if [ "$run_mtbseq" = true ] && [ "$run_snippy" = true ] && [ "$run_tbprofiler" = false ]; then
    ask_for_another
elif [ "$run_mtbseq" = true ] && [ "$run_snippy" = false ] && [ "$run_tbprofiler" = true ]; then
    ask_for_another
elif [ "$run_mtbseq" = true ] && [ "$run_snippy" = false ] && [ "$run_tbprofiler" = false ]; then
    ask_for_another
elif [ "$run_mtbseq" = false ] && [ "$run_snippy" = true ] && [ "$run_tbprofiler" = true ]; then
    ask_for_another
elif [ "$run_mtbseq" = false ] && [ "$run_snippy" = true ] && [ "$run_tbprofiler" = false ]; then
    ask_for_another
elif [ "$run_mtbseq" = false ] && [ "$run_snippy" = false ] && [ "$run_tbprofiler" = true ]; then
    ask_for_another
fi



