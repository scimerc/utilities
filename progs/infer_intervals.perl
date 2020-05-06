#!/usr/bin/perl
use strict;
use warnings;
use lib '/cluster/projects/p33/groups/biostat/software/lib/perl';
use opt_manager;
use toolz;

my $program_description = " assemble intervals so that each has at least the minimum number of markers.\n" . 
                        " the count file has the format: <chromosome_arm>_<start>_<end>  <count>.\n";
my $program_usage = "\n  usage: " . toolz::pathless ( $0 ) . " [options]" . " <count file(s)>\n";

sub update_intervals
{
    my ( $array, $arm, $start, $stop, $count ) = @_;
    my $new_index = scalar ( @{$array} );
    while (
        $new_index > 0 and
        $array -> [ $new_index - 1 ] -> [ 0 ] eq $arm and 
        $array -> [ $new_index - 1 ] -> [ 1 ] >= $start 
    ) { $new_index--; }
    $array -> [ $new_index ] = [ $arm, $start, $stop, $count ];
    return $new_index;
}

my $composite_options = {
	't' => 100
};

my $help_messages = {
	't' => "minimum number of markers per interval;\n" .
		"if less, intervals will be merged."
};

opt_manager::init_help_message ( $program_description . $program_usage );
opt_manager::set_composite_options ( $composite_options, $help_messages );

my @inputarr = opt_manager::read ( @ARGV );

if ( scalar @inputarr > 0 )
{
	my $threshold = opt_manager::get ( 't' );
	print ( "minimum number of markers set to: ${threshold}\n" );
	foreach my $countfile ( @inputarr )
	{
		my @count_array = ();
		my @new_count_array = ();
		open ( my $fh, '<', $countfile ) or die "\n${countfile}: $!\n";
		while ( my $line = <$fh> )
		{
			chomp $line;
			my @info = split ( /[ \t]+/, $line );
			my $interval = $info [ 0 ];
			my $count = $info [ 1 ];
			my @interval_info = split ( '_', $interval );
			push @count_array, [ @interval_info, $count ];
		}
		close $fh;
		my $increment = 0;
        my $current_index = 0;
		for ( my $index = 0; $index < scalar ( @count_array ); $index += $increment )
		{
			my $arm = $count_array [ $index ] -> [ 0 ];
			my $start = $count_array [ $index ] -> [ 1 ];
			my $stop = $count_array [ $index ] -> [ 2 ];
			my $count = $count_array [ $index ] -> [ 3 ];
			$increment = 0;
			# if $count is low try extending forward
			while ( 
                $index + ++$increment < scalar ( @count_array ) and
                $count_array [ $index + $increment ] [ 0 ] eq $arm and
                $count < $threshold
            ) {
                $count += $count_array [ $index + $increment ] -> [ 3 ];
                $stop = $count_array [ $index + $increment ] -> [ 2 ];
            }
            if ( $count < $threshold and $new_count_array [ $current_index ] -> [ 0 ] eq $arm )
            {
                $count += $new_count_array [ 3 ];
                $start = $new_count_array [ $current_index ] -> [ 1 ];
                $new_count_array [ $current_index ] = [ $arm, $start, $stop, $count ];
            }
            else
            {
#                 $current_index = update_intervals ( \@new_count_array, $arm, $start, $stop, $count );
                $current_index = scalar ( @new_count_array );
                while (
                    $current_index > 0 and
                    $new_count_array [ $current_index - 1 ] -> [ 0 ] eq $arm and 
                    $new_count_array [ $current_index - 1 ] -> [ 1 ] >= $start 
                ) { $current_index--; }
                $new_count_array [ $current_index ] = [ $arm, $start, $stop, $count ];
            }
		}
		open ( my $gh, '>', $countfile . '.intervals' ) or die "\n$!\n";
		foreach my $entry ( @new_count_array )
		{
			printf ( $gh $entry -> [ 0 ] . '_' . $entry -> [ 1 ] . '_' . $entry -> [ 2 ] . "\n" );
		}
		close $gh;
	}
}
else
{
	print ( "\n missing input.\n" );
	print ( "\n  usage: " . toolz::pathless ( $0 ) . " [options]" . " <count file(s)>\n\n" );
}

