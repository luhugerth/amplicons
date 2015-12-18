#!/usr/bin/perl -w

=head1 NAME

rdp_parser

=head1 SYNOPSIS

	rdp_parser [--help] [--verbose] [--rdp_out] [--counts=<file>] --rdp=<file> --cutoff=<integer> --depth=<integer>

		Parses an RDP file into a table of taxa and counts.
		If option --rdp_out is activated, outputs an "RDP like" output.

		rdp: rdp all rank file
		counts: number of reads corresponding to each OTU. If missing, considered to be 1 for all OTU.
		cut: percentage confidence for a classification to be accepted. Default: 50.
		depth: taxonomic depth at which to classify; 1-domain, 7-species. Default: 3 (class)

	If using paired reads, concatenate the files and run the script.

=head1 AUTHOR

luisa.hugerth@scilifelab.se

=cut


use warnings;
use strict;

use Getopt::Long;
use Pod::Usage;

my $help = 0;
my $verbose = 0;
my $rdpfile;
my $maxdepth = 3;
my $cut=50;
my $rdp_out;
my $countfile;
GetOptions(
  "help!" => \$help,
  "verbose!" => \$verbose,
  "rdp=s" => \$rdpfile,
  "cutoff=i" => \$cut,
  "depth=i" => \$maxdepth,
  "rdp_out!" => \$rdp_out,
  "counts=s" => \$countfile
);

pod2usage(0) if $help;


pod2usage(-msg => "Need an RDP file", -exitval => 1) unless $rdpfile;
pod2usage(-msg => "Provide depth between 1 and 7", -exitval => 1) unless ($maxdepth>0 and $maxdepth <= 7);

open RDP, $rdpfile or die "Can't open $rdpfile: $!";

my %counts;
if ($countfile){
	open COUNTS, $countfile or die "Can't open $countfile: $!";
	while (my $line = <COUNTS>){
		$line=~/^(\S+)\t(\d+)/;
		$counts{$1}=$2;
	}
	close COUNTS;
}

my %matches1;
my %matches2;
my %score;
my $id;
my $depth;
$cut=$cut/100;
while (my $line = <RDP>){
	$depth=-1;
	unless ($line=~/^(#|Class|Taxon|Submit|Conf|Symbol|Query|\n)/){	#Skip headers
		#OTU_14;+;Root;100%;Bacteria;100%;"Proteobacteria";99%;Betaproteobacteria;99%;Rhodocyclales;61%;Rhodocyclaceae;61%;Methyloversatilis;17%
		chomp $line;
		my @fields = split (';', $line);
		my $id = shift @fields;	#Get read ID
#print "$id\n";
		shift @fields;
		if (exists ($matches1{$id})){	#Check whether this ID has seen before
			while (scalar (@fields)>0){
				$depth++;
				my $taxon = shift @fields;
				my $trust = shift @fields;
				$trust=~/(\d+)%/;
				$trust=$1;
				if ($trust>=$cut and $depth<=$maxdepth){	#Goes down to the selected depth,
					push (@{$matches2{$id}}, $taxon)		#unless low confidence
				}				
			}
		}
		 else{
			while (scalar (@fields)>0){	#If meeting and ID for the first time
				$depth++;
				my $taxon = shift @fields;
				#shift @fields;
				my $trust = shift @fields;
#print "$taxon\t$trust\n";
				$trust=~/(\d+)%/;
				$trust=$1;
				if ($trust>=$cut and $depth<=$maxdepth){	#Goes down to the selected depth,
					push (@{$matches1{$id}}, $taxon)		#unless low confidence
				}				
			 }
		 }
	}
}
close RDP;

my $STOP;
while (my ($id, $tax) = each %matches2){
## Compares the classification of indexes that appear twice 
## and takes the lowest consensus
	$STOP = 0;
	my ($this_tax, $that_tax);
	my $tax = '';
	my $depth=-1;
	while (scalar (@{$matches2{$id}}) > 0 and scalar(@{$matches1{$id}}) > 0){
		$this_tax = shift @{$matches2{$id}};
		$that_tax = shift @{$matches1{$id}};
		if ($this_tax eq $that_tax){
			$tax = $tax."$this_tax;" unless $rdp_out;
			$tax = $tax."$this_tax;$cut%;" if $rdp_out;
			$depth++;
		}
		 else{
			$STOP = 1;
		 }
	}
## If one of the classifications is not exhausted, but they agreed so far, continue digging
	while (scalar(@{$matches1{$id}}) > 0){
		$this_tax = shift @{$matches1{$id}};
		unless ($STOP == 1){
			$tax = $tax."$this_tax;" unless $rdp_out;
			$tax = $tax."$this_tax;$cut%;" if $rdp_out;
		}
		$depth++;
	}
	while (scalar(@{$matches2{$id}}) > 0){
		$this_tax = shift @{$matches2{$id}};
		unless ($STOP == 1){
			$tax = $tax."$this_tax;" unless $rdp_out;
			$tax = $tax."$this_tax;$cut%;" if $rdp_out;
		}
		$depth++;
	}
	if ($rdp_out){
		my $count = 1;
		chop($tax);
		if ($countfile){
			if (exists ($counts{$id})){
				$count = $counts{$id};
			}
			 else{
				$count = 0;
			 }
##update number, if the id exists
		}		
		while ($count > 0){
			print "$id;+;$tax\n";
			$count--;
		}
	}
	else{
#	elsif ($depth == $maxdepth){	#Print the consensus classification
		print "$id\t$tax\n";
#	}
	
#	 else{
#		print "$id\tUnclassified_$tax\n";	#Mark 'Unclassified' if shallow depth
	 }
	delete $matches1{$id};
}

while (my ($id, $tax) = each %matches1){	#Print classifications that occur only once
	my $tax = join(";", @{$matches1{$id}}) unless $rdp_out;
	my $depth = scalar(@{$matches1{$id}})-1;
	if ($rdp_out){
		$tax = join (";$cut%;", @{$matches1{$id}});
		my $count = 1;
		if ($countfile){
			if (exists ($counts{$id})){
				$count = $counts{$id};
			}
			 else{
				$count = 0;
			 }
		}
		while ($count > 0){
			print "$id;+;$tax;$cut%\n";
			$count--;
		}
	}
	elsif (exists($counts{$id})){
		my $count=$counts{$id};
		print "$id\t$tax\t$count\n";
	}
	 else{
		print "$id\t$tax\n";	#Mark 'Unclassified' if shallow depth
	 }
	delete $matches1{$id};
}
