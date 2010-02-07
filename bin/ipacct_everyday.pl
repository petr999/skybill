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
our $sth=$dbh->prepare("delete from clients where ts<now()-interval ? second");
$sth->execute(DB_CLISERV_KEEP);
$sth=$dbh->prepare("delete from servers where ts<now()-interval ? second");
$sth->execute(DB_CLISERV_KEEP);
$sth->finish();
$sth=$dbh->prepare("delete from ".DB_DETAILS_TABLE ." where day<now()-interval ? day");
$sth->execute(DB_DETAILS_KEEP);
$sth=$dbh->prepare("delete from ".DB_DETAILS_MONTHLY_TABLE ." where year*12+month<year( now()-interval ? month )*12+month(   now()-interval ? month )");
$sth->execute(DB_DETAILS_MONTHLY_KEEP, DB_DETAILS_MONTHLY_KEEP);
$dbh->disconnect;

