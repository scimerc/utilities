#!/usr/bin/perl
# package for handling command line simple and composite arguments
# allows to define your own argument lists
use strict;
use warnings;

package opt_manager;

my $program_description = '';

# composite options
# built-in for rear-compatibility with scripts that don't define their own options
my $composite_options = {
	'A' => '',
	'C' => '',
	'chr' => 9,
	'datafile' => '',
	'infile' => 'infile.dat',
	'outfile' => 'outfile.dat',
	'pattern' => ' ',
	'snp' => 'rs9999999',
	'snpdir' => '/nfs_mount/bioinfo/extdata/IMPUTEdata/1000g_20100707/CEU/snps',
	'table' => 'Proteins'
};

# simple options
my $simple_options = {
	'h' => 0,
	'v' => 0
};

# n. of characters in the key field for help messages
my $keyfield_length = 0;

# the actual help messages
my $help_container = {
	'h' => 'print a help message on screen and exit',
	'v' => 'set verbose mode'
};

# the following functions set the hash tables of
# function-specific option keys and values (eventually empty).
# the simple options 'h' (help) and 'v' (verbose) are hard-wired.
# both functions take a reference to hash as argument.

sub set_simple_options
{
	while ( my ( $key, $value ) = each %{$_[0]} )
	{
		$simple_options -> {$key} = $value;
		if ( scalar @_ > 1 and defined $_[1] -> {$key} )
		{
			$help_container -> {$key} = $_[1] -> {$key};
			if ( length $key > $keyfield_length ) {
			  $keyfield_length = length $key;
			}
		}
	}
}

sub set_composite_options
{
	while ( my ( $key, $value ) = each %{$_[0]} )
	{
		$composite_options -> {$key} = $value;
		if ( scalar @_ > 1 and defined $_[1] -> {$key} )
		{
			$help_container -> {$key} = $_[1] -> {$key};
			if ( length ( $key . "[ |=]<value>" ) > $keyfield_length ) {
			  $keyfield_length = length ( $key . "[ |=]<value>" )
			}
		}
	}
}

sub get
{
	if ( exists ( $simple_options -> {$_[0]} ) )
	{
		return $simple_options -> {$_[0]};
	}
	elsif ( exists ( $composite_options -> {$_[0]} ) )
	{
		return $composite_options -> {$_[0]};
	}
	else
	{
		print ( "opt_manager.get(): invalid option $_[0]\n" );
	}
}

sub set
{
	if ( exists ( $simple_options -> {$_[0]} ) )
	{
		$simple_options -> {$_[0]} = 1;
	}
	elsif ( exists ( $composite_options -> {$_[0]} ) )
	{
		$composite_options -> {$_[0]} = $_[1];
	}
	else
	{
		print ( "opt_manager.set(): invalid option '" . $_[0] . "'\n" );
	}
}

sub init_help_message
{
    $program_description = $_[0];
}

sub help_message
{
	my $buffer = $_[0];
	my $indent = '    ';
    my @sorted_help_keys = sort keys %$help_container;
	foreach my $key ( @sorted_help_keys )
	{
		my $linecount = 0;
		my @messagelines = split "\n", $help_container -> {$key};
		foreach my $line ( @messagelines )
		{
			my $cnt = 0;
			$buffer .= $indent;
			if ( $linecount == 0 )
			{
				$cnt = length $key;
				$buffer .= "-${key}";
				if ( exists ( $composite_options -> {$key} ) )
				{
					$buffer .= "[ |=]<value>";
					$cnt += length "[ |=]<value>";
				}
				$buffer .= "  ";
			}
			else
			{
				$buffer .= '   ';
			}
			while ( $cnt < $keyfield_length )
			{
				$buffer .= ' ';
				$cnt++;
			}
			$buffer .= "$line\n";
			$linecount++;
		}
	}
	return $buffer;
}

# reads the array of arguments passed to it,
# stores the simple and composite options and
# returns an array with all non-flagged arguments
sub read
{
	my $argcnt = 0;
	my @argarr = split ( /[ =]+/, join ( ' ', @_ ) );
	my @inputarr = ();
	foreach my $arg ( @argarr )
	{
		unless ( $arg eq '' )
		{
			if ( $arg =~ /^-(.+)/ )
			{
				if ( exists ( $simple_options -> {$1} ) )
				{
                    if ( $1 eq 'h' )
                    {
                        print ( "\n" . $program_description );
                        print ( "\n  options:\n" . opt_manager::help_message () . "\n" );
                        exit;
                    }
                    else
                    {
                        set ( $1 );
                    }
				}
				elsif ( exists ( $composite_options -> {$1} ) )
				{
					my $value = $argarr[$argcnt+1];
					set ( $1, $value );
					shift @argarr;
				}
				else
				{
					print ( "opt_manager.read(): invalid option '" . $1 . "'\n" );
                    print ( "consider re-running with with '-h'.\n" );
				}
			}
			else
			{
				push @inputarr, $arg;
			}
		}
		$argcnt++;
	}
	return @inputarr;
}

1;
