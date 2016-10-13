#!/usr/bin/perl -w

=head1 NAME

deplex

=head1 SYNOPSIS

	sum_otus [--help] --otu=<file> --uc=<file>

	  Extract subsequences from a fasta file.

	    --help: This info.
		--otu:	tsv OTU table with samples in columns, OTU in rows, taxonomy on second-to-last and centroid on last column
		--uc:	uc file from Usearch mapping the old OTU into the new, coarser-grained OTU

=head1 AUTHOR

luisa.hugerth@scilifelab.se

=cut


use warnings;
use strict;

use Getopt::Long;
use Pod::Usage;

my $help = 0;
my $verbose = 0;
my ($otufile, $ucfile);
GetOptions(
  "help!" => \$help,
  "verbose!" => \$verbose,
  "otu=s" => \$otufile,
  "uc=s" => \$ucfile
);

pod2usage(0) if $help;

pod2usage(-msg => "Need an otu file", -exitval => 1) unless $otufile;
pod2usage(-msg => "Need an UC file", -exitval => 1) unless $ucfile;

open OTU, $otufile or die "Can't open $otufile: $!";
open UC, $ucfile or die "Can't open $ucfile: $!";

my %intable;
my $header = "T"; 
my $line_len = 0;
while (my $line = <OTU>){
	if ($header eq "T"){
		print $line;
		$header = "F";
		chomp $line;
		my @line = split "\t", $line;
		$line_len = scalar(@line);
	}
	else{
		chomp $line;
		my @line = split "\t", $line;
		my $name = shift @line;
		@{$intable{$name}} = @line;
	}
}
close OTU;

my %outtable;

while (my $line = <UC>){
	chomp $line;
	my @line = split "\t", $line;
	my $otu = $line[-2];
	if ($line[0] eq "S"){
		@{$outtable{$otu}} = @{$intable{$otu}}
	}
	elsif ($line[0] eq "H"){
		my $centroid = $line[-1];
		for (my $i=0; $i<=($line_len - 4); $i++){
			$outtable{$centroid}[$i] += $intable{$otu}[$i];
		}
	}
}
close UC;

foreach my $otu (keys %outtable){
	my $line = join("\t", @{$outtable{$otu}});
	print "$otu\t$line\n";
}

