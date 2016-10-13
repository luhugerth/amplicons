#!/usr/bin/env python

""" 
map2otutab.py: takes a series of read mapping files to a closed references and makes an OTU table out of it
"""

from collections import defaultdict
import argparse
import csv
import re
import glob
import os

__author__ = "Luisa W Hugerth"
__email__ = "luisa.hugerth@scilifelab.se"


def parse_files(inpath, suffix, refnum):
	counts = defaultdict(lambda: defaultdict(int))
	termination = "*" + suffix
	samples = list()
	for filename in glob.glob(os.path.join(inpath, termination)):
		with open(filename) as csvfile:
			reader = csv.reader(csvfile, delimiter="\t")
			name = os.path.basename(filename)
			name = re.sub(suffix, "", name)
			samples.append(name)
			for row in reader:
				counts[row[refnum]][name] += 1
	return (counts, samples)
		
def printer(counts, samples):
	for otu, samplecount in counts.iteritems():
		outline = otu 
		for sample in samples:
			if sample in samplecount:
				outline = outline + "\t" + str(samplecount[sample])
			else:
				outline = outline + "\t0"
		print outline

def main(inpath, suffix, refnum):
	counts, samples = parse_files(inpath, suffix, refnum)
	print ("Taxon\t" + "\t".join(samples))
	printer(counts, samples)

if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='Makes OTU tables from closed reference mappings')
	parser.add_argument('-i', '--inpath', help='Folder containing the mapping files')
	parser.add_argument('-s', '--suffix', help='Common suffix to all mapping files')
	parser.add_argument('-r', '--reference', type=int, default=-1, help='Field in the parsed mapping file containing the reference. Default: %(default)i')
	args = parser.parse_args()

	main(args.inpath, args.suffix, args.reference)

