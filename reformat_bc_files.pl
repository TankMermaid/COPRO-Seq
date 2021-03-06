#!/usr/bin/env perl

# Takes as input the .bc/.mapping files and .scarf symbolic links generated by batch_coproseq.pl 
# and produces the corresponding barcode-split .scarf files that can be submitted to GEO when
# COPRO-Seq data must be deposited

use strict;

# Inputs:
#	X.mapping (used to figure out what BC name goes with each sample)
#	X.bc (used to get the barcode sequences and run_lane info)

# Open the .mapping file and load a hash with the contents; key = sample name, value = BC name
# Open the .bc file and grab the file prefix (run_lane), and the file elements (BC seq, sample name)
# Output new .bc file: [BC name] \t [BC seq] \t run[run#]_lane[lane#]_[BC name].scarf

check_args(@ARGV);
my $bc_names = get_bc_names($ARGV[0]);		# $bc_names = ref. to hash (key = sample name, value = barcode name)
my ($run, $lane) = get_run_info_from_bc_file($ARGV[1]);
#print "Run: $run\nLane: $lane\n";
make_new_bc_file($ARGV[1], $bc_names, $run, $lane);
exit;

sub make_new_bc_file {
	my ($filename, $bc_names_by_sample, $run, $lane) = @_;
	my @line;
	my $new_filename;
	if (! $ARGV[2]) {
		$new_filename = $run."_".$lane."\.bc_new";
	}
	else { $new_filename = $ARGV[2]; }
	#print "New filename: $new_filename\n";
	open(BC, $filename) || report_error(4);
	open(OUTPUT, ">$new_filename") || report_error(6);
	while(<BC>) {
		chomp;
		@line = split(/\t/, $_);
		if (defined $$bc_names_by_sample{$line[1]}) {
			print OUTPUT $$bc_names_by_sample{$line[1]}."\t".$line[0]."\t"."run".$run."_lane".$lane."_".$$bc_names_by_sample{$line[1]}."\.scarf\n";
		}
		else {
			print "WARNING: Cannot find a barcode name for sample $line[1] in .bc file!\n";
		}
	}
	close OUTPUT;
	close BC;
}

sub get_run_info_from_bc_file {
	my $filename = shift;
	my ($run, $lane);
	if ($filename =~ /(.*).bc$/) {
		my @info = split("_", $1);
		$info[0] =~ s/\.\.\///;		# Eliminate any leading ../ in front of .bc path
		$run = $info[0];
		$lane = $info[1];
	}
	else { report_error(2); }
	return($run, $lane);
}

sub get_bc_names {
	my $mapping_file = shift;
	my %bc_names_for_samples;
	open(MAPPING, $mapping_file) || report_error(3);
	my @line;
	while (<MAPPING>) {
		chomp;
		@line = split(/\t/, $_);
		$bc_names_for_samples{$line[1]} = $line[2];
	}
	close MAPPING;
	return \%bc_names_for_samples;
}

sub check_args {	
	if ((scalar @_ != 2) && (scalar @_ != 3)) { report_error(5); }
	my ($mapping_file, $old_bc_file) = @_;
	unless ($mapping_file =~ /\.mapping$/) { report_error(1); }
	unless ($old_bc_file =~ /\.bc$/) { report_error(2); }
}

sub report_error {
	my $code = shift;
	if ($code == 1)		{ print "\nYour mapping file appears to be named incorrectly (should be [run]_[lane].mapping)!\n\n"; }
	elsif ($code == 2)	{ print "\nYour barcode file appears to be named incorrectly (should be [run]_[lane].bc)!\n\n"; }
	elsif ($code == 3)	{ print "\nCannot open your mapping (.mapping) file!\n\n"; }
	elsif ($code == 4)	{ print "\nCannot open your barcode (.bc) file!\n\n"; }
	elsif ($code == 5)	{ print "\nIncorrect number of parameters passed to reformat_bc_files.pl\nUsage: reformat_bc_files.pl [.mapping file] [.bc file] [optional: output file name]\n\n"; }
	exit;
}
