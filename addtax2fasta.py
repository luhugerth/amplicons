#!/usr/bin/env python

""" addtax2fasta.py: takes a fasta file with incomplete taxonomy headers and one with complete; completes both

"""

from collections import defaultdict
from operator import add
import argparse
import csv
import re

__author__ = "Luisa W Hugerth"
__email__ = "luisa.hugerth@scilifelab.se"


def refparse(reffile, field):
	refdict = dict()
	with open(reffile) as csvfile:
		reader = csv.reader(csvfile, delimiter=" ")
		for row in reader:
			if row[0][0] == ">":
				tax_string = row[1]
				tax = tax_string.split(";")
				tax = tax[:field+1]	
				tax_string = ";".join(tax)
				#print(tax[field+1])
				#print(tax_string)
				if (tax_string != "uncultured" and tax_string != "Incertae_Sedis"):
					refdict[tax[field+1]] = tax_string
	return refdict
	
def rewrite(infile, reftax):
	with open(infile) as csvfile:
		reader = csv.reader(csvfile, delimiter=" ")
		for row in reader:
			if row[0][0] == ">":
				cpn60 = row[0]
				ncbi = row[1]
				taxonomy = row[2:]
				taxon = "_".join(taxonomy)
				genus = taxonomy[0]
				if (genus in reftax):
					phylogeny = reftax[genus]
					print(" ".join([cpn60, ncbi, ";".join([phylogeny, taxon])]))
				else:
					print(" ".join([cpn60, ncbi, taxon]))
			else:
				print row[0]


def main(infile, reffile, field):
	reftax = refparse(reffile, field)
	rewrite(infile, reftax)


if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='Completes taxonomy in one fasta file based on another')
	parser.add_argument('-i', '--infile', help='Fasta file to complete with taxonomy')
	parser.add_argument('-r', '--reference', help='Fasta file with complete taxonomic information')
	parser.add_argument('-f', '--field', type=int, default=-2, help='Which field in the ;-separated full taxonomy to map to the infile. Default: %(default)i')
	args = parser.parse_args()

	main(args.infile, args.reference, args.field)

