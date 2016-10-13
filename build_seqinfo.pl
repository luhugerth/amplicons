#!/usr/bin/perl -w

=head1 NAME

build_seqinfo.pl

=head1 SYNOPSIS

	build_seqinfo.pl [--help] --fasta=<file> --id_file=<file> 

	  Outputs a csv file in format seqname,tax_id,tax_name
		eg	AY236502.1.1489,47917,Serratia fonticola

	    --help: This info.
		--fasta: fasta file containing sequence id and sequence taxonomy
		--id_file: file in format ncbi_node_id # seq_taxonomy

=head1 AUTHOR

luisa.hugerth@scilifelab.se

=cut

use warnings;
use strict;

use Bio::SeqIO;
use Getopt::Long;
use Pod::Usage;

my $help = 0;
my $verbose = 0;
my ($fafile, $idfile);
GetOptions(
  "help!" => \$help,
  "verbose!" => \$verbose,
  "fasta=s" => \$fafile,
  "id_file=s" => \$idfile
);

pod2usage(0) if $help;

pod2usage(-msg => "Need a fasta file", -exitval => 1) unless $fafile;
pod2usage(-msg => "Need a tax file", -exitval => 1) unless $idfile;

open TAX, $idfile or die "Can't open $idfile: $!";
open FASTA, $fafile or die "Can't open $fafile: $!";

my %taxtable;
while (my $line = <TAX>){
	chomp $line;
	$line=~/(\d+) # (.+)$/;
	my $tax_id=$1;
	my $tax=$2;
	$taxtable{$tax}=$tax_id;
}
close TAX;

while (my $line = <FASTA>){
	if ($line=~/^>/){
		$line=~/(\S+)\s(.+)/;
		my $seq_id = $1;
		my @fulltax = split(";", $2);
		my $tax = $fulltax[-1];
		if (exists $taxtable{$tax}){
			print "$seq_id,".$taxtable{$tax}.",$tax\n";
		}
	}
}
close FASTA;

