#!/usr/bin/env python

""" 
validate_sam.py: removes records from a sam file with an invalid cigar
"""

from collections import defaultdict
import argparse
import csv
import re


__author__ = "Luisa W Hugerth"
__email__ = "luisa.hugerth@scilifelab.se"


def get_cigar_len(cigar):
	cigar = re.sub("M", "_", cigar)
        cigar = re.sub("I", "_", cigar)
        cigar = re.sub("D", "_", cigar)
        cigar = re.sub("N", "_", cigar)
        cigar = re.sub("S", "_", cigar)
        cigar = re.sub("H", "_", cigar)
        cigar = re.sub("P", "_", cigar)
	basecounts = cigar.split("_")
	length = 0
	for count in basecounts:
		if (count != ""):
			length = length + int(count)
	return length
	

def validate(cigar):
	good = True
	for char in cigar:
		if not re.match("\w", char):
			good = False
		if re.match("_", char):
			good = False
	return (good)

def main(infile):
#	with open(infile) as csvfile:
#		reader = csv.reader(csvfile, delimiter="\t")
#		for row in reader:
	row = infile.readline()
	row.rstrip()
	if row[0] == '@':
		print row
	else:
		row = row.split("\t")
		cigar = row[5]
		if (cigar == '*'):
			print "\t".join(row)
		else:
			if (validate(cigar)):
				seqlen = len(row[9])
				quallen = len(row[10])
				if (seqlen == quallen):
					ciglen = get_cigar_len(cigar)
					if (ciglen == seqlen):
						print "\t".join(row)
 


if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='Removes lines with invalid CIGAR strings from a SAM file')
	parser.add_argument('-i', '--infile', help='Path to the sam file')
	args = parser.parse_args()

	main(args.infile)

