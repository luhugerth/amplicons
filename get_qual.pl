#!/usr/bin/perl -w

=head1 NAME

get_qual

=head1 SYNOPSIS

        perl get_qual.pl [--help] --fasta=<file> --fastq1=<file> --fastq2=<file>

        	Gets the original quality information from a fastq file
		back to the fasta.
		Written for interleaved Cassava <1.8 style, must expand.

	--help: This info.
	--fasta: fasta file containing a subset of the samples in the fastq,
		possibly trimmed at the 3' end.
	--fastq1: original fastq file for the forward read
	--fastq2: original fastq file for the reverse read

		Output files are <fastq_file>.1.fastq and <fastq_file>.2.fastq

=head1 AUTHOR

luisa.hugerth@scilifelab.se

=cut

use warnings;
use strict;

use Getopt::Long;
use Pod::Usage;
use Bio::SeqIO;

my $help = 0;
my $verbose = 0;
my ($fastafile, $fastqfile1, $fastqfile2);
GetOptions(
  "help!" => \$help,
  "verbose!" => \$verbose,
  "fasta=s" => \$fastafile,
  "fastq1=s" => \$fastqfile1,
  "fastq2=s" => \$fastqfile2
);

pod2usage(0) if $help;

pod2usage(-msg => "Need fastq files", -exitval => 1) unless ($fastqfile1 and $fastqfile2);
pod2usage(-msg => "Need a fasta file", -exitval => 1) unless $fastafile;

open FASTQ1, $fastqfile1 or die "Can't open $fastqfile1: $!";
open FASTQ2, $fastqfile2 or die "Can't open $fastqfile2: $!";
my $infasta = Bio::SeqIO->new(-file=>"$fastafile", -format => "fasta") or die "Can't open $fastafile";


my (%fwd, %rev);
while (my $seq = $infasta->next_seq){
	my $length = length ($seq->seq);
	my $id = $seq->display_id;
	if ($id=~/(1$| 1:N:\d+:\w+$)/){
		$id=~/([\w\d:]+)\/1$/;	
		$fwd{$1}=$length;
	}
	 elsif ($seq->display_id=~/(2$| 2:N:\d+:\w+$)/){
                $id=~/([\w\d:]+)\/2$/;   
                $rev{$1}=$length;
	 }
	 else{
		print "Warning: file might not be properly interleaved";
	 }
}

open OUT1, ">$fastqfile1.1.fastq";
my ($id, $exists, $is_seq);
while (my $line = <FASTQ1>){
	chomp $line;
	if ($line=~/^\@HISEQ/){
		$line=~/^@(\S+)/;
		$id=$1;
		$exists=0;
		if (exists $fwd{$id}){
			print OUT1 "\@$id\n";
			$exists=1;
			$is_seq=1;
		}
	}
	 elsif ($line!~/^\+$/ and $exists==1){
		my $newseq=substr $line, 0, $fwd{$id};
		if ($is_seq==1){
			print OUT1 "$newseq\n+\n";
			$is_seq=0;
		}
		 else{
			print OUT1 "$newseq\n";
		 }
	}
}

open OUT2, ">$fastqfile2.2.fastq";
while (my $line = <FASTQ2>){
	chomp $line;
	if ($line=~/^\@HISEQ/){
		$line=~/^@(\S+)/;
		$id=$1;
		$exists=0;
		if (exists $rev{$id}){
			print OUT2 "\@$id\n";
			$exists=1;
			$is_seq=1;
		}
	}
	 elsif ($line!~/^\+$/ and $exists==1){
		my $newseq=substr $line, 0, $rev{$id};
		if ($is_seq==1){
			print OUT2 "$newseq\n+\n";
			$is_seq=0;
		}
		 else{
			print OUT2 "$newseq\n";
		 }
	}
}

close FASTQ1;
close FASTQ2;
close OUT1;
close OUT2;


