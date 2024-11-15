# WGS_to_AMR

![Test](https://github.com/SeviJordi/WGS_to_AMR/actions/workflows/test.yaml/badge.svg)

Improved prediction of AMR in *Klebsiella pneumoniae* using machine learning

---
This repository contains the data and scripts to predict antimicrobial resistance (AMR) to amikacin, fosfomycin and piperacillin/tazobactm on *K. pneumoniae* using machine learning.

## Installation

First, clone this repository or download the zipped version (find the button on the right-hand side of the screen).

```
git clone git@github.com:SeviJordi/WGS_to_AMR.git
cd WGS_to_AMR
```

To use this repository, the programs and libraries specified in [requirements.txt](requirements.yaml) have to be installed. They can be installed using conda:

```
conda env create -f requirements.yaml
conda activate AMR_prediction
```
## Usage

The main script is [predict_AMR.sh](predict_AMR.sh) and it take to args. The `-o` arg specifies the file to store the results and the `-i` arg provides the input genomes in fasta format.

```
Usage: predict_AMR.sh -o [OUTPUT FILE] -i [[INPUT_GENOMES]...].
Predict resistance to amikacin, fosfomycin and piperacillin/tazobactam

Options:
  -o  Output file to save the results
  -i  Input genomes in FASTA format
```

## Test

Within this repository, four *K. pneumoniae* genomes are provided to test the prediction. To verify that all installations have been completed successfully, run:

```
bash predict_AMR.sh -o .test/output.csv -i .test/data/*
```

## Output

The output a CSV file with 4 columns. The genome ID retrived from the genome file, the antibiotic for wich the prediction is made, the probability of resistance, and the R/S prediction based on a probability threshold. You can find an example of the output in [output.csv](.test/output.csv)


