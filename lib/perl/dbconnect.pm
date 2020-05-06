#!/usr/bin/perl

package dbconnect;

use strict;

use DBI;

# parameters
my $host 		= 'coulomb.chemie.fu-berlin.de';
my $user		= 'knappipedia';
my $pass		= 'trustno1';
my $dbase		= 'ssepred';
my $table		= 'Proteins';
my $query		= 0;

# database object
my $dbh;
my $sth;

# job id
my $id;

sub start
{
	# flush
	select ( ( select ( STDOUT ), $| = 1 )[0] );

	# connect to $dbase
	$table = $_[0];
	$dbh = DBI->connect("dbi:mysql:${dbase}:${host}", $user, $pass) ||
	die "The database connection couldn't be established: $DBI::errstr";

	# return
	return $dbh;
}

sub getDomainID
{
	$query = 1;
	$sth = $dbh->prepare("SELECT `ID` FROM ${table} WHERE `Name`='" . $_[0] . "'");
	$sth->execute();

	my @rs = $sth->fetchrow_array();
	return $rs[0];
}

sub getDomainName
{
	$query = 1;
	$sth = $dbh->prepare("SELECT `Name` FROM ${table} WHERE `ID`='" . $_[0] . "'");
	$sth->execute();

	my @rs = $sth->fetchrow_array();
	return $rs[0];
}

# close database objects
sub finish
{
	$sth->finish() if ( $query == 1 );
	$dbh->disconnect();
}

1;
