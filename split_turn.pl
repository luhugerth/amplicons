#!/usr/bin/perl -w

=head1 NAME

split_turn.pl

=head1 SYNOPSIS

	perl split_turn.pl [--help]  [--verbose] --infile=<fasta> --len=<integer>

		Splits a read in a determined point, reverse complements the second part and joins them back.

			--help: This info.
			--infile: fasta file to split and reverse complement the end
			--len: length of the forward read (part not to turn)

=head1 AUTHOR
luisa.hugerth@scilifelab.se

=cut


use warnings;
use strict;
use Bio::SeqIO;
use Bio::Perl;
use Getopt::Long;
use Pod::Usage;

my $infile;
my $length=0;
my $help = 0;
my $verbose = 0;
GetOptions(
 "infile=s" => \$infile,
 "len=i" => \$length,
 "help!" => \$help,
 "verbose!" => \$verbose
);

pod2usage(0) if $help;
pod2usage(-msg => "Need an input fasta files", -exitval => 1) unless $infile;
my $file = Bio::SeqIO->new(-file=>"$infile", -format => "fasta") or die "Can't open $infile";

while(my $seq=$file->next_seq){
	my $read=$seq->seq;
	my $first_half=substr($read, 0, $length);
	my $sec_half=substr($read, $length);
	$sec_half=reverse_complement_as_string($sec_half);
	print ">".$seq->display_id."\n$first_half$sec_half\n";
}
