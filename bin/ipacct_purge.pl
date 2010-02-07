#!/usr/bin/perl -w

use strict;
use warnings;

our $skybill_lib;

BEGIN{
	use Cwd qw/realpath getcwd/;
	use File::Basename qw/dirname/;
	$skybill_lib = realpath( dirname( __FILE__ )."/../lib" );
	unshift( @INC, $skybill_lib ) unless grep { $_ eq $skybill_lib } @INC;
}

use DBI;
use DBD::mysql;
use Skybill::Config;

our $dbh=DBI->connect("DBI:mysql:database=".DB_NAME.";mysql_socket=".DB_SOCK,DB_USER,DB_PASS);

purge_raw( DB_RAW_KEEP );

$dbh->disconnect;

sub purge_raw{
	my $keep = shift();
	my $sth=$dbh->prepare( "delete from ".DB_RAW_TABLE." where unix_timestamp( ts ) < unix_timestamp() - ?" );
	$sth->execute( $keep );
#	$sth=$dbh->prepare( "delete from raw_out where unix_timestamp( ts ) < unix_timestamp() - ?" );
#	$sth->execute( $keep );
}
