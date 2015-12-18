#!/usr/bin/perl -w

=head1 NAME

amplicon_stats

=head1 SYNOPSIS

	trim_to_pos [--help] [--verbose] [--include] --fwd=INT --rev=INT db.fasta

	  Gives the length of amplicons.
	
		--fwd, rev: position of first and last base to keep
		db.fasta: fasta file (gapped or not); output will be unaligned
	    --help: This info.
	    

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
my $include = 0;
my $fwd;
my $rev;

GetOptions(
  "help!" => \$help,
  "verbose!" => \$verbose,
  "fwd=i" => \$fwd,
  "rev=i" => \$rev,
);

pod2usage(0) if $help;

my $dbfile = shift(@ARGV);
pod2usage(-msg => "Need a dbfile", -exitval => 1) unless $dbfile;
my $infile = Bio::SeqIO->new(-file=>"$dbfile", -format => "fasta") or die "Can't open $dbfile";

my $len = $rev - $fwd;

while (my $record = $infile->next_seq){
	my $seq = $record->seq;
	$seq=~/^(.+){$fwd}(.+){$len}/;
	my $amplicon = $2;
	print ">".$record->display_id."\n";
	print "$amplicon\n";
}


