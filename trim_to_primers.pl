#!/usr/bin/perl -w

=head1 NAME

amplicon_stats

=head1 SYNOPSIS

	trim_to_primers [--help] [--verbose] [--include] --fwd=STRING --rev=STRING db.fasta

	  Gives the length of amplicons.
	
		--fwd, rev: primers to generate amplicons
		--include: keep primer sequences in the output; default, remove
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
  "fwd=s" => \$fwd,
  "rev=s" => \$rev,
  "include!" => \$include
);

pod2usage(0) if $help;

my $dbfile = shift(@ARGV);
pod2usage(-msg => "Need a dbfile", -exitval => 1) unless $dbfile;
my $infile = Bio::SeqIO->new(-file=>"$dbfile", -format => "fasta") or die "Can't open $dbfile";

sub regenerate{
	my $seq=$_[0];
	$seq=~s/U/T/g;
	$seq=~s/R/[AG]/g;
	$seq=~s/Y/[CT]/g;
	$seq=~s/S/[GC]/g;
	$seq=~s/W/[AT]/g;
	$seq=~s/K/[GT]/g;
	$seq=~s/M/[AC]/g;
	$seq=~s/B/[CGT]/g;
	$seq=~s/D/[AGT]/g;
	$seq=~s/H/[ACT]/g;
	$seq=~s/V/[ACG]/g;
	$seq=~s/N/[ACTG]/g;
	return $seq;
}

$fwd = regenerate($fwd);
$rev = regenerate($rev);

while (my $record = $infile->next_seq){
	my $seq = $record->seq;
	$seq=~s/_//g;
	if ($seq=~/$fwd/ and $seq=~/$rev/){
		my $amplicon;
		if ($include){
			$seq=~/($fwd.+$rev)/;
			$amplicon = $1;
		}
		 else{
			$seq=~/$fwd(.+)$rev/;
			$amplicon = $1;
		 }
		print ">".$record->display_id."\n";
		print "$amplicon\n";
	}
}


