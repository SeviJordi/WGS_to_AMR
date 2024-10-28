#!/usr/bin/bash

# Jordi Sevilla Fortuny

# Set data files
amik_kmers="data/amikacin.kmers.txt"
fosfo_kmers="data/fosfomycin.kmers.txt"
pip_kmers="data/pip_taz.kmers.txt"
amik_model="data/amikacin.model.rds"
fosfo_model="data/fosfomycin.model.rds"
pip_model="data/pip_taz.model.rds"

# Side functions
help() {
    echo "Usage: $0 [FASTA FILES]."
    echo "Predict resistance to amikacin, fosfomycin and pieracillin/tazobactam"
    echo ""
}

logthis() {
    echo "$(date) - $1"
}

findKmers () {

    name=$(basename $1 | cut -d '.' -f 1)
    glistmaker $1 -w 15 -o kmers_${name}

    glistquery kmers_${name}_15.list -f $3 > ${2}/${name}@fosfo.txt
    glistquery kmers_${name}_15.list -f $4 > ${2}/${name}@amika.txt
    glistquery kmers_${name}_15.list -f $5 > ${2}/${name}@pip.txt

	rm kmers_${name}_15.list

}
# usage findKmers [genome] [temp_dir] [fosfo kmers] [amik kmers] [pier kmers]
export -f findKmers

#################################################
# Main
#################################################
logthis "Predicting AMR"

# Check arguments
if [ $# -lt 1 ]; then
    help
    exit 1
fi

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
parallel findKmers {} $tmp_dir $fosfo_kmers $amik_kmers $pip_kmers ::: $@

# Creating input matrix
logthis "Creating input matrix for fosfomycin"
python3 src/create_matrix.py $fosfo_kmers $tmp_dir/matrix_fosfo.txt $tmp_dir/*@fosfo.txt

logthis "Creating input matrix for amikacin"
python3 src/create_matrix.py $amik_kmers $tmp_dir/matrix_amik.txt $tmp_dir/*@amika.txt

logthis "Creating input matrix for pip/taz"
python3 src/create_matrix.py $pip_kmers $tmp_dir/matrix_pip.txt $tmp_dir/*@pip.txt


# Predicting resistance
Rscript --vanilla src/evaluate.R $fosfo_model $tmp_dir/matrix_fosfo.txt \
    $amik_model $tmp_dir/matrix_amik.txt \
    $pip_model $tmp_dir/matrix_pip.txt \
    output.csv

logthis "Results saved in output.csv"

# Clean up
rm -r $tmp_dir

logthis "script finished"

