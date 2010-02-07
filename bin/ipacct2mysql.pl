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
our $bytes_sum=0;

our $sth=$dbh->prepare("INSERT INTO ".DB_RAW_TABLE."( src, src_port, dest, dest_port, proto, bytes, packets) VALUES(inet_aton( ? ),?,inet_aton( ? ),?,?,?,?)");
while(<STDIN>) {
    chomp;				# here we now get a string!
my ( $src, $src_port, $dest, $dest_port, $proto, $bytes, $packets )=split(' ');
	#	if(
	#			(	grep( { $src eq $_ } @{( SERVERS_LIST )} )
	#					and
	#				grep( { $src_port == $_ } @{( SERVERS_PORTEXCLUDE_LIST )} )
	#			)
	#			or
	#			not (
	#				grep( { $dest eq $_ } @{( SERVERS_LIST )} )
	#					and
	#				grep( { $dest_port == $_ } @{( SERVERS_PORTEXCLUDE_LIST )} )
	#			)
	#	){
    $sth->execute(
    $src,
    $src_port,
    $dest,
    $dest_port,
    $proto,
    $bytes,
    $packets) or die $dbh->errstr;
	#	}
	$bytes_sum+=$bytes; # if DB_RAW_TABLE eq DB_RAW_TABLE_IN;
}
	daily_sum(); # if DB_RAW_TABLE eq DB_RAW_TABLE_IN;

$dbh->disconnect;

sub daily_sum{
	$sth=$dbh->prepare( "select count(*) from ".DB_DAILY_TABLE." where day=date( now() )" );
	$sth->execute(); my ( $day_exists ) = $sth->fetchrow_array();
	my $sql= $day_exists ? "update ".DB_DAILY_TABLE." set bytes=bytes+? where day=date( now() )" :
	"insert into ".DB_DAILY_TABLE." ( day, bytes ) values ( now(), ? )";
	$sth=$dbh->prepare( $sql ); $sth->execute( $bytes_sum ) or die "cannot transfer data to daily";
}
