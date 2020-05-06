#!/usr/bin/perl
use strict;
use warnings;
use lib '/cluster/projects/p33/groups/biostat/software/lib/perl';
use opt_manager;
use dbconnect;

my $buffer = '';

opt_manager::set_composite_options ( { 'asd' => "", 'age' => 21, 'name' => 'al' } );
opt_manager::set_simple_options ( { 'v' => 0, 'express' => 0 } );
opt_manager::read ( @ARGV );
