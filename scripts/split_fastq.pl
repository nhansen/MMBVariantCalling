#!/usr/bin/perl -w
##########################################################
# Author:	Nancy Hansen
# Date:		11/5/2012
# Program:	split_fastq.pl
# Function:	split a fastq file evenly into a number
#               of subfiles.
##########################################################

use strict;
use Getopt::Long;

my $Usage = "split_fastq.pl <fastq_file> <# of files to split into> <--gzip> <--nogzip> <-dir subdirectory name>\n";

my $directory = '.'; # default is to write to this directory.
my ($gzip, $nogzip); # options to gzip output fastq files (or not)

# specify output directory for files, or whether to gzip output files
GetOptions("dir=s" => \$directory, "gzip" => \$gzip, "nogzip" => \$nogzip); 

$directory =~ s:/$::; # no trailing / on directory name

($#ARGV == 1)
  or die "$Usage";

my $fastq_file = $ARGV[0];  
my $no_output_files = $ARGV[1];

my $linecountstring = ($fastq_file =~ /\.gz$/) ? `gunzip -c $fastq_file | wc -l` : `wc -l $fastq_file`;

chop $linecountstring;
$linecountstring =~ s/\s+\S+$//;

my $openstring = ($fastq_file =~ /\.gz$/) ? "gunzip -c $fastq_file | " : $fastq_file;

open FASTQ, $fastq_file
    or die "Couldn\'t open $fastq_file: $!\n";

my $no_entries = int($linecountstring/(4*$no_output_files)) + 1;

my $file_no = 1;
my $fastq_base = $fastq_file;
$fastq_base =~ s:.*/::;
my $out_file = "$directory/$fastq_base";
if ($out_file =~ /\.f(ast){0,1}q(\.gz){0,1}$/)
{
    $out_file =~ s:\.fastq(?!\.gz{0,1})$:.fq:;
    $out_file =~ s:(\.fq(\.gz){0,1})$:.1$1:;
    if ($out_file eq $fastq_file) {
        die "Refusing to overwrite original fastq file ($fastq_file, $out_file)!\n";
    }
    if ($nogzip && $out_file =~ /\.gz$/) {
        $out_file =~ s/\.gz$//;
    }
    elsif ($gzip && $out_file !~ /\.gz$/) {
        $out_file .= '.gz';
    }
}
else
{
    $out_file .= '.1.fastq.gz';
    if ($nogzip) {
        $out_file =~ s/\.gz$//;
    }
}

my $openwritestring = ($out_file =~ /\.gz$/) ? " | gzip -c > $out_file " : ">$out_file";
open OUTFASTQ, $openwritestring
    or die "Couldn\'t open file $openwritestring for writing: $!\n";

print "Writing $out_file.\n";

my $line_no = 0;
while (<FASTQ>)
{
    $line_no++;
    print OUTFASTQ "$_";

    if ($line_no >= $no_entries*4)
    {
        close OUTFASTQ
            or die "Couldn\'t close file $!\n";

        my $old_file_no = $file_no;
        $file_no++;
        $out_file =~ s:\.$old_file_no(\.fq(\.gz){0,1})$:.$file_no$1:;

        $openwritestring = ($out_file =~ /\.gz$/) ? " | gzip -c > $out_file " : ">$out_file";
        open OUTFASTQ, $openwritestring
            or die "Couldn\'t open $openwritestring:$!\n";
        $line_no = 0;
        print "Writing $out_file.\n";
    }
}

close OUTFASTQ
    or die "Couldn\'t close file $!\n";

close FASTQ;
