#!/usr/bin/bash

# Jordi Sevilla Fortuny

# get script dir
scd=$(dirname $0)

# Set data files
amik_kmers="$scd/data/amikacin.kmers.txt"
fosfo_kmers="$scd/data/fosfomycin.kmers.txt"
pip_kmers="$scd/data/pip_taz.kmers.txt"
amik_model="$scd/data/amikacin.model.rds"
fosfo_model="$scd/data/fosfomycin.model.rds"
pip_model="$scd/data/pip_taz.model.rds"

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

    glistquery kmers_${name}_15.list -f $3 > ${2}/${name}@fosfo.txt
    glistquery kmers_${name}_15.list -f $4 > ${2}/${name}@amika.txt
    glistquery kmers_${name}_15.list -f $5 > ${2}/${name}@pip.txt

	rm kmers_${name}_15.list

}
# usage findKmers [genome] [temp_dir] [fosfo kmers] [amik kmers] [pier kmers]
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
parallel findKmers {} $tmp_dir $fosfo_kmers $amik_kmers $pip_kmers ::: ${input_files[@]}

# Creating input matrix
logthis "Creating input matrix for fosfomycin"
python3 $scd/src/create_matrix.py $fosfo_kmers $tmp_dir/matrix_fosfo.txt $tmp_dir/*@fosfo.txt

logthis "Creating input matrix for amikacin"
python3 $scd/src/create_matrix.py $amik_kmers $tmp_dir/matrix_amik.txt $tmp_dir/*@amika.txt

logthis "Creating input matrix for pip/taz"
python3 $scd/src/create_matrix.py $pip_kmers $tmp_dir/matrix_pip.txt $tmp_dir/*@pip.txt


# Predicting resistance
Rscript --vanilla $scd/src/evaluate.R $fosfo_model $tmp_dir/matrix_fosfo.txt \
    $amik_model $tmp_dir/matrix_amik.txt \
    $pip_model $tmp_dir/matrix_pip.txt \
    $output_file

logthis "Results saved in $output_file"

# Clean up
rm -r $tmp_dir

logthis "script finished"

