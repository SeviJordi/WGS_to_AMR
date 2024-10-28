#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# libraries
import numpy as np
import pandas as pd
import re
from sys import argv


# Side functions
def get_header(path_all_kmers: str) -> str:
    """ Create the header for a train matrix

    Args:
        path_all_kmers (str): List of all kmers present in train samples

    Returns:
        str: header line for the dataframe
    """
    f = open(path_all_kmers)

    header = "ID"
    for line in f:
        kmer = line.strip()
        header += f",{kmer}"
    
    header += "\n"
    return header

def sparse_data(file_name: str) -> str: 
    """ Generate binary output for kmers in sample

    Args:
        file_name (str): file with kmers counts for sample

    Returns:
        str: Line with binary output
    """

    f = open(file_name)
    name = file_name.split("/")[-1].split("@")[0]
    text = "{}".format(name)

    for line in f:
  
        _,num = line.strip().split("\t")
        if int(num) > 0:
            text += ",1"
        else:
            text += ",0"
    
    text += "\n"
    f.close()
    return text
        
def write_matrix(kmers: list, file):

    for path in kmers:
        new_line = sparse_data(path)
        file.write(new_line)


def main():
    kmers = argv[3:]
    w = open(argv[2],"w")

    header = get_header(argv[1])
    w.write(header)
    
    write_matrix(kmers,w)
    
    w.close()


if __name__ == "__main__" :
    main()