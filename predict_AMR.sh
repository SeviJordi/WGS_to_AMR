#!/usr/bin/bash

# Jordi Sevilla Fortuny

# get script dir
scd=$(dirname $0)

# Side functions
help() {
    echo "Usage: $0 -o [OUTPUT FILE] -i [INPUT_GENOMES]."
    echo "Predict resistance to amikacin, fosfomycin and pieracillin/tazobactam"
    echo ""
    echo "Options:"
    echo "  -o  Output file to save the results"
    echo "  -i  Input genomes in fasta format"
    echo ""
}

logthis() {
    echo "$(date) - $1"
}

findKmers () { 

    name=$(basename $1)
    name=${name%.*}
    
    glistmaker $1 -w 15 -o kmers_${name}

    for atb in $(cat $3); do
      glistquery kmers_${name}_15.list -f $4/$atb.kmers > ${2}/${name}@$atb.txt
    done

	rm kmers_${name}_15.list

}
# usage findKmers [genome] [temp_dir] [atbs] [path_to_kmers]
export -f findKmers


# Check arguments
# Initialize variables for options
input_files=()

# Loop through arguments manually
while getopts "o:i:" opt; do
  case ${opt} in
    o )
      output_file="$OPTARG"
      ;;
    i )
      # Add all remaining arguments as batch files starting from current position
      shift $((OPTIND - 2))
      while [[ "$1" && "$1" != -* ]]; do
        input_files+=("$1")
        shift
      done
      ;;
    \? )
      help
      exit 1
      ;;
  esac
done


# Check if output_file is set and input_files is not empty
if [ -z "$output_file" ] || [ ${#input_files[@]} -eq 0 ]; then
  help
  exit 1
fi
#################################################
# Main
#################################################
logthis "Predicting AMR"

# Check dependencies
if ! command -v glistmaker &> /dev/null; then
    logthis "glistmaker not found. Please install it."
    exit 1
fi

if ! command -v glistquery &> /dev/null; then
    logthis "glistquery not found. Please install it."
    exit 1
fi

if ! command -v parallel &> /dev/null; then
    logthis "parallel not found. Please install it."
    exit 1
fi

# Create temporary directory
tmp_dir=$(mktemp -d)
logthis "Temporary directory: $tmp_dir"

# Predict AMR
# Find kmers for each genome
logthis "Finding kmers in genomes"
parallel findKmers {} $tmp_dir $scd/data/Atbs.txt $scd/data/ ::: ${input_files[@]}

# Creating input matrix
for atb in $(cat $scd/data/Atbs.txt); do
  logthis "Creating input matrix for $atb"
  python3 $scd/src/create_matrix.py $scd/data/${atb}.kmers $tmp_dir/matrix_${atb}.txt $tmp_dir/*@$atb.txt
done

# Predicting resistance
Rscript --vanilla $scd/src/evaluate.R $scd/data/Atbs.txt  $scd/data/ $tmp_dir $output_file

logthis "Results saved in $output_file"

# Clean up
rm -r $tmp_dir

logthis "script finished"

