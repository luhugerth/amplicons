#!/usr/bin/perl -w

=head1 NAME

format_for_qiime

=head1 SYNOPSIS

	format_for_qiime [--help] [--verbose] [--name=<string>] --in=<FASTA> 

		Formats the headers of a fasta file for qiime usage.
		Original headers are preserved as comments.
		If sample name is not the same as the file name, this can be given as an additional parameter.


=head1 AUTHOR

luisa.hugerth@scilifelab.se

=cut


use warnings;
use strict;

use Getopt::Long;
use Pod::Usage;
use File::Basename;

my $help = 0;
my $verbose = 0;
my $infile;
my $name;
GetOptions(
  "help!" => \$help,
  "verbose!" => \$verbose,
  "in=s" => \$infile,
  "name=s" => \$name
);

pod2usage(0) if $help;

pod2usage(-msg => "Need a fastx infile", -exitval => 1) unless $infile;

open IN, $infile or die "Can't open $infile: $!";

unless ($name){
	$name = basename($infile);
	$name =~ /^(\S+).fa(sta)?$/;
	$name = $1;
}

my $count = 1;
while (my $line = <IN>){
	if ($line =~ /^>/){
		$line =~ /^>(.+)/;
		print ">${name}_$count $1\n";
		$count++;
	}
	 else{
		print $line;
	 }
}
close IN;
