#!/usr/bin/perl -w
#########################################################
# Author:	Nancy F. Hansen
# Program:	filter_reference.pl
# Function:	Read in a reference FASTA file, and 
#		write out the file without known alternate
#               haplotype sequences and with masked
#               pseudoautosomal regions on the Y 
#               chromosome.
#
# Date:		April 7, 2015
##########################################################

use strict;
use Getopt::Long;
use Pod::Usage;
use FileHandle;

our %Opt;

my $ra_alt_seqs = set_alt_seqs();
my $ra_par_coords = set_parmask_coords();

my $Usage = "Usage: filter_reference.pl <--build build_name> <--input reference_fasta> <--output filtered_reference_fasta>\nFor more information, type \"perldoc filter_reference.pl.";

process_commandline();

($#ARGV < 0)
    or die "$Usage";

my $build = $Opt{'build'} || '';
my $input = $Opt{'input'};
my $output = $Opt{'output'};

if (!$input || !$output) {
    die "Must specify an input FASTA path with --input and an output FASTA path with --output";
}

# read in sequence entries one at a time, process, then output:
$/ = "\n>";
my $inputstring = ($input =~ /\.gz$/) ? "gunzip -c $input | " : $input;
my $fh = FileHandle->new($inputstring)
    or die "Couldn\'t open $input for reading: $!\n";
my $outputstring = ($output =~ /\.gz$/) ? "| gzip -c > $output " : ">$output";
my $outfh = FileHandle->new($outputstring)
    or die "Couldn\'t open $output for writing: $!\n";

while (<$fh>) {
    my $entry = $_;
    $entry =~ s/\n>//;
    $entry =~ s/>//;
    my ($desc_line, $sequence) = split /\n/, $entry, 2;
    my ($desc, $remainder) = ($desc_line =~ /^(\S+)\s+(.*)$/) ? ($1, $2) : ($desc_line, '');
    $sequence =~ s/\n//g;
    my $length = length($sequence);

    # skip any entry listed in "alt_seqs" list for build, or if no such list exists,
    # skip entries with "alt" or "hap" in their names (case insensitive)

    if (($ra_alt_seqs->{$build} && 
            grep {$_ eq $desc} @{$ra_alt_seqs->{$build}}) ||
            (!$ra_alt_seqs->{$build} && ($desc =~ /alt/ || 
            $desc =~ /hap/i))) {
        next;
    }

    if (($build) && $ra_par_coords->{$build} && 
              $ra_par_coords->{$build}->{$desc}) {
        foreach my $ra_coord (@{$ra_par_coords->{$build}->{$desc}}) {
            my ($start, $end) = @{$ra_coord};

            my $nlength = $end - $start + 1;
            my $n_string = create_nstring($nlength);

            print "Offset: $start - 1, length $nlength\n";
            substr($sequence, $start-1, $nlength) = $n_string;
        }
    }

    print_fasta($outfh, $desc_line, $sequence, $Opt{linelength});
    print STDERR "Wrote $desc_line (length $length)\n";
}

$fh->close();

# parse the command line arguments to determine program options
sub process_commandline {
    
    # Set defaults here
    %Opt = ( 
               linelength => 50 
           );
    GetOptions(\%Opt, qw(
                build=s input=s output=s linelength=i help+ version verbose
               )) || pod2usage(0);
    if ($Opt{help})    { pod2usage(verbose => $Opt{help}); }
    if ($Opt{version}) { die "$0, ", q$Revision: $, "\n"; }

}

sub set_alt_seqs {

    return { 'hg17' => [],
             'hg18' => [],
             'hg19' => [],
             'hg38' => ['chr1_KI270762v1_alt', 'chr1_KI270766v1_alt' , 'chr1_KI270760v1_alt' , 'chr1_KI270765v1_alt' , 'chr1_GL383518v1_alt' , 'chr1_GL383519v1_alt' , 'chr1_GL383520v2_alt' , 'chr1_KI270764v1_alt' , 'chr1_KI270763v1_alt' , 'chr1_KI270759v1_alt' , 'chr1_KI270761v1_alt' , 'chr2_KI270770v1_alt' , 'chr2_KI270773v1_alt' , 'chr2_KI270774v1_alt' , 'chr2_KI270769v1_alt' , 'chr2_GL383521v1_alt' , 'chr2_KI270772v1_alt' , 'chr2_KI270775v1_alt' , 'chr2_KI270771v1_alt' , 'chr2_KI270768v1_alt' , 'chr2_GL582966v2_alt' , 'chr2_GL383522v1_alt' , 'chr2_KI270776v1_alt' , 'chr2_KI270767v1_alt' , 'chr3_JH636055v2_alt' , 'chr3_KI270783v1_alt' , 'chr3_KI270780v1_alt' , 'chr3_GL383526v1_alt' , 'chr3_KI270777v1_alt' , 'chr3_KI270778v1_alt' , 'chr3_KI270781v1_alt' , 'chr3_KI270779v1_alt' , 'chr3_KI270782v1_alt' , 'chr3_KI270784v1_alt' , 'chr4_KI270790v1_alt' , 'chr4_GL383528v1_alt' , 'chr4_KI270787v1_alt' , 'chr4_GL000257v2_alt' , 'chr4_KI270788v1_alt' , 'chr4_GL383527v1_alt' , 'chr4_KI270785v1_alt' , 'chr4_KI270789v1_alt' , 'chr4_KI270786v1_alt' , 'chr5_KI270793v1_alt' , 'chr5_KI270792v1_alt' , 'chr5_KI270791v1_alt' , 'chr5_GL383532v1_alt' , 'chr5_GL949742v1_alt' , 'chr5_KI270794v1_alt' , 'chr5_GL339449v2_alt' , 'chr5_GL383530v1_alt' , 'chr5_KI270796v1_alt' , 'chr5_GL383531v1_alt' , 'chr5_KI270795v1_alt' , 'chr6_GL000250v2_alt' , 'chr6_KI270800v1_alt' , 'chr6_KI270799v1_alt' , 'chr6_GL383533v1_alt' , 'chr6_KI270801v1_alt' , 'chr6_KI270802v1_alt' , 'chr6_KB021644v2_alt' , 'chr6_KI270797v1_alt' , 'chr6_KI270798v1_alt' , 'chr7_KI270804v1_alt' , 'chr7_KI270809v1_alt' , 'chr7_KI270806v1_alt' , 'chr7_GL383534v2_alt' , 'chr7_KI270803v1_alt' , 'chr7_KI270808v1_alt' , 'chr7_KI270807v1_alt' , 'chr7_KI270805v1_alt' , 'chr8_KI270818v1_alt' , 'chr8_KI270812v1_alt' , 'chr8_KI270811v1_alt' , 'chr8_KI270821v1_alt' , 'chr8_KI270813v1_alt' , 'chr8_KI270822v1_alt' , 'chr8_KI270814v1_alt' , 'chr8_KI270810v1_alt' , 'chr8_KI270819v1_alt' , 'chr8_KI270820v1_alt' , 'chr8_KI270817v1_alt' , 'chr8_KI270816v1_alt' , 'chr8_KI270815v1_alt' , 'chr9_GL383539v1_alt' , 'chr9_GL383540v1_alt' , 'chr9_GL383541v1_alt' , 'chr9_GL383542v1_alt' , 'chr9_KI270823v1_alt' , 'chr10_GL383545v1_alt', 'chr10_KI270824v1_alt', 'chr10_GL383546v1_alt', 'chr10_KI270825v1_alt', 'chr11_KI270832v1_alt', 'chr11_KI270830v1_alt', 'chr11_KI270831v1_alt', 'chr11_KI270829v1_alt', 'chr11_GL383547v1_alt', 'chr11_JH159136v1_alt', 'chr11_JH159137v1_alt', 'chr11_KI270827v1_alt', 'chr11_KI270826v1_alt', 'chr12_GL877875v1_alt', 'chr12_GL877876v1_alt', 'chr12_KI270837v1_alt', 'chr12_GL383549v1_alt', 'chr12_KI270835v1_alt', 'chr12_GL383550v2_alt', 'chr12_GL383552v1_alt', 'chr12_GL383553v2_alt', 'chr12_KI270834v1_alt', 'chr12_GL383551v1_alt', 'chr12_KI270833v1_alt', 'chr12_KI270836v1_alt', 'chr13_KI270840v1_alt', 'chr13_KI270839v1_alt', 'chr13_KI270843v1_alt', 'chr13_KI270841v1_alt', 'chr13_KI270838v1_alt', 'chr13_KI270842v1_alt', 'chr14_KI270844v1_alt', 'chr14_KI270847v1_alt', 'chr14_KI270845v1_alt', 'chr14_KI270846v1_alt', 'chr15_KI270852v1_alt', 'chr15_KI270851v1_alt', 'chr15_KI270848v1_alt', 'chr15_GL383554v1_alt', 'chr15_KI270849v1_alt', 'chr15_GL383555v2_alt', 'chr15_KI270850v1_alt', 'chr16_KI270854v1_alt', 'chr16_KI270856v1_alt', 'chr16_KI270855v1_alt', 'chr16_KI270853v1_alt', 'chr16_GL383556v1_alt', 'chr16_GL383557v1_alt', 'chr17_GL383563v3_alt', 'chr17_KI270862v1_alt', 'chr17_KI270861v1_alt', 'chr17_KI270857v1_alt', 'chr17_JH159146v1_alt', 'chr17_JH159147v1_alt', 'chr17_GL383564v2_alt', 'chr17_GL000258v2_alt', 'chr17_GL383565v1_alt', 'chr17_KI270858v1_alt', 'chr17_KI270859v1_alt', 'chr17_GL383566v1_alt', 'chr17_KI270860v1_alt', 'chr18_KI270864v1_alt', 'chr18_GL383567v1_alt', 'chr18_GL383570v1_alt', 'chr18_GL383571v1_alt', 'chr18_GL383568v1_alt', 'chr18_GL383569v1_alt', 'chr18_GL383572v1_alt', 'chr18_KI270863v1_alt', 'chr19_KI270868v1_alt', 'chr19_KI270865v1_alt', 'chr19_GL383573v1_alt', 'chr19_GL383575v2_alt', 'chr19_GL383576v1_alt', 'chr19_GL383574v1_alt', 'chr19_KI270866v1_alt', 'chr19_KI270867v1_alt', 'chr19_GL949746v1_alt', 'chr20_GL383577v2_alt', 'chr20_KI270869v1_alt', 'chr20_KI270871v1_alt', 'chr20_KI270870v1_alt', 'chr21_GL383578v2_alt', 'chr21_KI270874v1_alt', 'chr21_KI270873v1_alt', 'chr21_GL383579v2_alt', 'chr21_GL383580v2_alt', 'chr21_GL383581v2_alt', 'chr21_KI270872v1_alt', 'chr22_KI270875v1_alt', 'chr22_KI270878v1_alt', 'chr22_KI270879v1_alt', 'chr22_KI270876v1_alt', 'chr22_KI270877v1_alt', 'chr22_GL383583v2_alt', 'chr22_GL383582v2_alt', 'chrX_KI270880v1_alt' , 'chrX_KI270881v1_alt' , 'chr19_KI270882v1_alt', 'chr19_KI270883v1_alt', 'chr19_KI270884v1_alt', 'chr19_KI270885v1_alt', 'chr19_KI270886v1_alt', 'chr19_KI270887v1_alt', 'chr19_KI270888v1_alt', 'chr19_KI270889v1_alt', 'chr19_KI270890v1_alt', 'chr19_KI270891v1_alt', 'chr1_KI270892v1_alt' , 'chr2_KI270894v1_alt' , 'chr2_KI270893v1_alt' , 'chr3_KI270895v1_alt' , 'chr4_KI270896v1_alt' , 'chr5_KI270897v1_alt' , 'chr5_KI270898v1_alt' , 'chr6_GL000251v2_alt' , 'chr7_KI270899v1_alt' , 'chr8_KI270901v1_alt' , 'chr8_KI270900v1_alt' , 'chr11_KI270902v1_alt', 'chr11_KI270903v1_alt', 'chr12_KI270904v1_alt', 'chr15_KI270906v1_alt', 'chr15_KI270905v1_alt', 'chr17_KI270907v1_alt', 'chr17_KI270910v1_alt', 'chr17_KI270909v1_alt', 'chr17_JH159148v1_alt', 'chr17_KI270908v1_alt', 'chr18_KI270912v1_alt', 'chr18_KI270911v1_alt', 'chr19_GL949747v2_alt', 'chr22_KB663609v1_alt', 'chrX_KI270913v1_alt' , 'chr19_KI270914v1_alt', 'chr19_KI270915v1_alt', 'chr19_KI270916v1_alt', 'chr19_KI270917v1_alt', 'chr19_KI270918v1_alt', 'chr19_KI270919v1_alt', 'chr19_KI270920v1_alt', 'chr19_KI270921v1_alt', 'chr19_KI270922v1_alt', 'chr19_KI270923v1_alt', 'chr3_KI270924v1_alt' , 'chr4_KI270925v1_alt' , 'chr6_GL000252v2_alt' , 'chr8_KI270926v1_alt' , 'chr11_KI270927v1_alt', 'chr19_GL949748v2_alt', 'chr22_KI270928v1_alt', 'chr19_KI270929v1_alt', 'chr19_KI270930v1_alt', 'chr19_KI270931v1_alt', 'chr19_KI270932v1_alt', 'chr19_KI270933v1_alt', 'chr19_GL000209v2_alt', 'chr3_KI270934v1_alt' , 'chr6_GL000253v2_alt' , 'chr19_GL949749v2_alt', 'chr3_KI270935v1_alt' , 'chr6_GL000254v2_alt' , 'chr19_GL949750v2_alt', 'chr3_KI270936v1_alt' , 'chr6_GL000255v2_alt' , 'chr19_GL949751v2_alt', 'chr3_KI270937v1_alt' , 'chr6_GL000256v2_alt' , 'chr19_GL949752v1_alt', 'chr6_KI270758v1_alt' , 'chr19_GL949753v2_alt', 'chr19_KI270938v1_alt',
] };

}

sub set_parmask_coords {

    return { 'hg17' => {'chrY' => [[1,2692881], [57372174,57701691]]},
             'hg18' => {'chrY' => [[1, 2709520], [57443438, 57772954]]},
             'hg19' => {'chrY' => [[10001, 2649520], [59034050, 59363566]]},
             'hg38' => {'chrY' => [[10000, 2781479], [56887902, 57217415]]}
    };
}

sub create_nstring {
    my $nlength = shift;
    my $nstring = 'N';
    my $nstringlength = 1;

    while (2*$nstringlength <= $nlength) {
        $nstring = $nstring.$nstring;
        $nstringlength *= 2;
    }

    while ($nstringlength < $nlength) {
        $nstring .= 'N';
        $nstringlength++;
    }

    my $endlength = length($nstring);
    if ($nstringlength != $nlength || $endlength != $nlength) {
        die "Wrong string length in create_nstring!\n";
    }
    return $nstring;
}

sub print_fasta {
    my $outfh = shift;
    my $displayid = shift;
    my $sequence = shift;
    my $linelength = shift || 50;

    print $outfh ">$displayid\n";

    # fast reformat stolen from Bioperl:
    my $formatstring = 'A'.$linelength;
    my $formatted_seq = join("\n", unpack("($formatstring)*", $sequence))."\n";
    print $outfh $formatted_seq;
}

=pod

=head1 NAME

filter_reference.pl - remove alternate haplotype sequence entries from a multi-FASTA reference file, and mask pseudoautosomal regions, if appropriate.

=head1 SYNOPSIS

When alignment and variant calling software is unaware of alternate haplotypes present in a reference assembly, misalignment and incorrect variant calling can occur.  In addition, pseudoautosomal regions on the sex chromosomes of an assembly can look like exact repeats, causing aligners to mis-classify alignments to these regions as repetitive, and potentially resulting in a lack of variant calls in these regions.  This script filters alternate haplotype sequences out of a reference assembly, and masks the pseudoautosomal region of chrY, when coordinates are available.

=head1 DESCRIPTION

The script currently has information for human assemblies hg17, hg18, hg19, and hg38.  To create a multi-FASTA file which is ready for formatting for your favorite aligner, run

filter_reference.pl --build <build> --input <input fasta> --output <output fasta>

=head1 INPUT

=head1 OPTIONS

=over 5

=item B<--build> I<build_name>

This option specifies the name of the UCSC build for this assembly (e.g., hg18, hg38).

=item B<--input> I<input_fasta>

This option specifies the path to a FASTA-formatted file of reference sequences.

=item B<--output> I<output_fasta>

This option specifies the path to the filtered FASTA file that will be created.

=item B<--linelength> I<length>

This option specifies the length of the lines containing sequence to print in FASTA
format.

=back

=head1 OUTPUT

=head1 AUTHOR

 Nancy F. Hansen - nhansen@mail.nih.gov

=head1 LEGAL

This software/database is "United States Government Work" under the terms of
the United States Copyright Act.  It was written as part of the authors'
official duties for the United States Government and thus cannot be
copyrighted.  This software/database is freely available to the public for
use without a copyright notice.  Restrictions cannot be placed on its present
or future use. 

Although all reasonable efforts have been taken to ensure the accuracy and
reliability of the software and data, the National Human Genome Research
Institute (NHGRI) and the U.S. Government does not and cannot warrant the
performance or results that may be obtained by using this software or data.
NHGRI and the U.S.  Government disclaims all warranties as to performance,
merchantability or fitness for any particular purpose. 

In any work or product derived from this material, proper attribution of the
authors as the source of the software or data should be made, using "NHGRI
Genome Technology Branch" as the citation. 

=cut

__END__
