#!/usr/bin/perl
# various utilities
use strict;
use warnings;

package toolz;

# $nucleocode:  hash containing the nucleotide one letter codes and their corresponding numerical codes
my $nucleocode = {
	'a' => 1,
	'c' => 2,
	'g' => 3,
	't' => 4,
	'A' => 1,
	'C' => 2,
	'G' => 3,
	'T' => 4
};


# $N = number_of_genotypes ( $ploidy, $Nalleles )
sub number_of_genotypes
{
	my $ploidy = $_[0];
	my $Nalleles = $_[1];

	return ( 
        factorial ( $ploidy + $Nalleles - 1 ) / 
        ( factorial ( $ploidy ) * factorial ( $Nalleles - 1 ) ) 
    );
}


# @interval = binary_close_field_search ( $target, $array, $field )
#        $array points to a $field-sorted array
#   on return,
#      the smallest array index interval containing $target
#
sub binary_close_field_search
{
	use integer;

	my ( $target, $array, $field ) = @_;

	my ( $low, $high ) = ( 0, scalar ( @$array ) - 1 );

	while ( ( $low < $high ) and $array->[$high]->[$field] != $target )
	{
		# try the middle element.
		my $cur = ( $low + $high ) / 2;
		if ( $array->[$cur]->[$field] < $target )
		{
			$low = $cur + 1;
		}
		else
		{
			$high = $cur;
		}
	}
	return ( $low, $high );
}


# $index = binary_close_search ( $array, $target )
#        $array points to a sorted array
#   on return,
#      the smallest array index interval containing $target
#
sub binary_close_search
{
	use integer;

	my ( $target, $array ) = @_;

	my ( $low, $high ) = ( 0, scalar ( @$array ) - 1 );

	while ( ( $low < $high ) and $array->[$high] != $target )
	{
		# try the middle element
		my $cur = ( $low + $high ) / 2;
		if ( $array->[$cur] < $target )
		{
			$low = $cur + 1;
		}
		else
		{
			$high = $cur;
		}
	}
	return ( $low, $high );
}


# $index = binary_field_search ( $target, $array, $field )
#        $array points to a $field-sorted array
#   on return,
#     either (if the element was in the array) index correponding to the element
#     or (if the element was not in the array) -1
#
sub binary_field_search
{
	use integer;

	my ( $target, $array, $field ) = @_;

	my ( $low, $high ) = ( 0, scalar ( @$array ) - 1 );

	while ( ( $low < $high ) and $array->[$high]->[$field] != $target )
	{
		# try the middle element.
		my $cur = ( $low + $high ) / 2;
		if ( $array->[$cur]->[$field] < $target )
		{
			$low = $cur + 1;
		}
		else
		{
			$high = $cur;
		}
	}
	if ( $array->[$high]->[$field] == $target )
	{
		return $high;
	}
	else
	{
		return -1;
	}
}


# $index = binary_search ( $array, $target )
#        $array points to a sorted array
#   on return,
#     either (if the element was in the array) index correponding to the element
#     or (if the element was not in the array) -1
#
sub binary_search
{
	use integer;

	my ( $target, $array ) = @_;

	my ( $low, $high ) = ( 0, scalar ( @$array ) - 1 );

	while ( ( $low < $high ) and $array->[$high] != $target )
	{
		# try the middle element
		my $cur = ( $low + $high ) / 2;
		if ( $array->[$cur] < $target )
		{
			$low = $cur + 1;
		}
		else
		{
			$high = $cur;
		}
	}
	if ( $array->[$high] == $target )
	{
		return $high;
	}
	else
	{
		return -1;
	}
}


# @interval = binary_close_field_text_search ( $target, $array, $field )
#        $array points to a $field-sorted array
#   on return,
#      the smallest array index interval containing $target
#
sub binary_close_field_text_search
{
	use integer;

	my ( $target, $array, $field ) = @_;

	my ( $low, $high ) = ( 0, scalar ( @$array ) - 1 );

	while ( ( $low < $high ) and $array->[$high]->[$field] ne $target )
	{
		# try the middle element.
		my $cur = ( $low + $high ) / 2;
		if ( $array->[$cur]->[$field] lt $target )
		{
			$low = $cur + 1;
		}
		else
		{
			$high = $cur;
		}
	}
	return ( $low, $high );
}


# $index = binary_close_text_search ( $array, $target )
#        $array points to a sorted array
#   on return,
#      the smallest array index interval containing $target
#
sub binary_close_text_search
{
	use integer;

	my ( $target, $array ) = @_;

	my ( $low, $high ) = ( 0, scalar ( @$array ) - 1 );

	while ( ( $low < $high ) and $array->[$high] ne $target )
	{
		# try the middle element
		my $cur = ( $low + $high ) / 2;
		if ( $array->[$cur] lt $target )
		{
			$low = $cur + 1;
		}
		else
		{
			$high = $cur;
		}
	}
	return ( $low, $high );
}


# $index = binary_field_search ( $target, $array, $field )
#        $array points to a $field-sorted array
#   on return,
#     either (if the element was in the array) index correponding to the element
#     or (if the element was not in the array) -1
#
sub binary_field_text_search
{
	use integer;

	my ( $target, $array, $field ) = @_;

	my ( $low, $high ) = ( 0, scalar ( @$array ) - 1 );

	while ( ( $low < $high ) and $array->[$high]->[$field] ne $target )
	{
		# try the middle element.
		my $cur = ( $low + $high ) / 2;
		if ( $array->[$cur]->[$field] lt $target )
		{
			$low = $cur + 1;
		}
		else
		{
			$high = $cur;
		}
	}
	if ( $array->[$high]->[$field] eq $target )
	{
		return $high;
	}
	else
	{
		return -1;
	}
}


# $index = binary_search ( $array, $target )
#        $array points to a sorted array
#   on return,
#     either (if the element was in the array) index correponding to the element
#     or (if the element was not in the array) -1
#
sub binary_text_search
{
	use integer;

	my ( $target, $array ) = @_;

	my ( $low, $high ) = ( 0, scalar ( @$array ) - 1 );

	while ( ( $low < $high ) and $array->[$high] ne $target )
	{
		# try the middle element
		my $cur = ( $low + $high ) / 2;
		if ( $array->[$cur] lt $target )
		{
			$low = $cur + 1;
		}
		else
		{
			$high = $cur;
		}
	}
	if ( $array->[$high] eq $target )
	{
		return $high;
	}
	else
	{
		return -1;
	}
}


sub count_lines
{
	my $lines = 0;
	my $buffer = '';
	my ( $filename, $chunksize ) = @_;
	open my ( $fh ), '<:raw', $filename or die "\n${filename}: $!\n";
	while ( sysread $fh, $buffer, $chunksize )
	{
		$lines += ( $buffer =~ tr/\n// );
	}
	close $fh;
	return $lines;
}


sub count_zlines
{
	my $lines = 0;
	my $buffer = '';
	my ( $filename, $chunksize ) = @_;
	open my ( $fh ), '-|', "zcat ${filename}" or die "\n${filename}: $!\n";
	while ( sysread $fh, $buffer, $chunksize )
	{
		$lines += ( $buffer =~ tr/\n// );
	}
	close $fh;
	return $lines;
}


sub factorial
{
	my ( $num ) = @_;
	if ( $num == 1 )
	{
		return 1;   # stop at 1, factorial doesn't multiply times zero
	}
	else
	{
		return $num * factorial ( $num - 1 );   # call factorial function recursively
	}
}


# pathless():   function which removes the path information up to the last '/' from a string assumed to be a filename
sub pathless
{
	# removes the path information leaving only the file name (or directory name)
	my $name = $_[0];
	if ( $name =~ /.*\/(.*)/ )
	{
		$name = $1;
	}
	return $name;
}


sub read_file
{
	# reads the given fields (space-type-separated) from the given file
	my ( $filename, @fields ) = ( $_[0], () );
	( $filename, @fields ) = @_ if ( scalar @_ > 1 );
	my @array = ();
	open my ( $fh ), '<', $filename or die "can't open ${filename}: $!";
	while ( my $line = <$fh> )
	{
		chomp $line;
		my @data = split /[ \t]+/, $line;
		my @data_slice = @data;
		@data_slice = @data_slice[@fields] unless ( scalar @fields == 0 );
		push @array, \@data_slice;
	}
	close $fh;
	return \@array;
}

1;
