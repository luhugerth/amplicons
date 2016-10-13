#!/usr/bin/env python

""" make_taxaDB.py: combines a uc file with a tsv of taxonomy to produce a taxonomy for each reference sequence

"""

from collections import defaultdict
from os.path import commonprefix
import argparse
import csv

__author__ = "Luisa W Hugerth"
__email__ = "luisa.hugerth@scilifelab.se"



def read_tax(infile):
	tax = dict()
	with open(infile) as csvfile:
		reader = csv.reader(csvfile, delimiter="\t")
		for row in reader:
			tax[row[0]] = row[1]
	return(tax)


def map_tax(mapfile, taxref):
	taxdict = dict()
	with open(mapfile) as csvfile:
		reader = csv.reader(csvfile, delimiter="\t")
		for row in reader:
			if (row[8] in taxref):
				tax = taxref[row[8]]
			else:
				tax = "Unclassified"
			refseq = row[9]
			if refseq in taxdict:
				taxdict[refseq] = commonprefix([taxdict[refseq], tax])
			else:
				taxdict[refseq] = tax
	return (taxdict)

#def printer():

def main(mapping, taxonomy):
	tax = read_tax(taxonomy)
	taxdict = map_tax(mapping, tax)
	for seq, tax in taxdict.iteritems():
		print seq + "\t" + tax


if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='Parses a UC table and another tsv table to produce a consensus taxonomy')
	parser.add_argument('-i', '--mapping', help='UC file')
	parser.add_argument('-db', '--taxonomy', help='TSV file with tab between ID and taxonomy and ; between each taxonomy level')
	args = parser.parse_args()

	main(args.mapping, args.taxonomy)

