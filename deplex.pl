#!/usr/bin/perl -w

=head1 NAME

deplex

=head1 SYNOPSIS

	deplex [--help] --bc1=<file> [--bc2=<file>] --fastq=<file> --bcnames=<file> [--suffix=<string>]

	  Extract subsequences from a fasta file.

	    --help: This info.
		--bc1: barcode 1 fastq file
		--bc2: barcode 2 fastq file (optional)
		--fastq: fastq file to deplex
		--bcnames: table associating barcode pair and a name for it, used for output
		--suffix: string to add after the barcode name in the output file [optional]

=head1 AUTHOR

luisa.hugerth@scilifelab.se

=cut


use warnings;
#use strict;

use Getopt::Long;
use Pod::Usage;

my $help = 0;
my $verbose = 0;
my ($bc1file, $bc2file, $fqfile, $bcnames);
my $suffix = "";
GetOptions(
  "help!" => \$help,
  "verbose!" => \$verbose,
  "bc1=s" => \$bc1file,
  "bc2=s" => \$bc2file,
  "fastq=s" => \$fqfile,
  "bcnames=s" => \$bcnames,
  "suffix=s" => \$suffix
);

pod2usage(0) if $help;

pod2usage(-msg => "Need a fastq file", -exitval => 1) unless $fqfile;
pod2usage(-msg => "Need a barcode file", -exitval => 1) unless $bc1file;
pod2usage(-msg => "Need the barcode names", -exitval => 1) unless $bcnames;

open NAMES, $bcnames or die "Can't open $bcnames: $!";
open BC1, $bc1file or die "Can't open $bc1file: $!";
(open BC2, $bc2file or die "Can't open $bc2file: $!") if $bc2file;
open FQ, $fqfile or die "Can't open $fqfile: $!";

my %bctable;
while (my $line = <NAMES>){
	$line=~/(\S+)\t(\w+)/;
	my $name=$1;
	my $bc=$2;
	$bctable{$bc}=$name;
#	my $fh = $bc."_out";
	open ($bc, ">", "$name-$suffix.fq");
}
close NAMES;

my @barcodes;
my $counter=0;
while (my $line = <BC1>){
	$counter++;
	if ($counter%4 == 2){
		chomp $line;
		push (@barcodes, $line);
		
	}
}
close BC1;
$counter=0;

if ($bc2file){
	while (my $line = <BC2>){
		$counter++;
		if ($counter%4 == 2){
			chomp $line;
			my $pos = ($counter-2)/4;
			$barcodes[$pos]=$barcodes[$pos].$line;
#print $barcodes[$pos]."\n";
		}
	}
	close BC2;
}
$counter=0;

my $outputfile;
open (my $other_out, ">nondeplex-$suffix.fq");
while (my $line = <FQ>){
	$counter++;
	if ($counter%4 == 1){
		my $barcode = shift(@barcodes);
		if (exists ($bctable{$barcode})){
			$outputfile = $barcode;
		}
		 else{
			$outputfile = $other_out;
		 }
		print $outputfile $line;
	}
	 else{
		print $outputfile $line;
	 }
}
close FQ;
close $other_out;

foreach my $bc (keys %bctable){
	close $bc;
}
#close all others, figure it out
