#!/usr/bin/perl -w

use strict;
use warnings;

=pod

=head1 NAME

 ipacct2mysql - script to pass statistics to mysql raw table from the ipacctd socket

=head1 LICENSE

 Copyright (c) 2010 Peter Vereshagin
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

=cut

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

our $dbh=DBI->connect("DBI:mysql:database=".DB_NAME.";".DB_DSN_REST,DB_USER,DB_PASS);
our $bytes_sum=0;

our $sth=$dbh->prepare("INSERT INTO ".DB_RAW_TABLE."( src, src_port, dest, dest_port, proto, bytes, packets) VALUES( ?,?,?,?,?,?,?)");
while(<STDIN>) {
    chomp;				# here we now get a string!
my ( $src, $src_port, $dest, $dest_port, $proto, $packets, $bytes, )=split /\s+/, $_;
  $proto = lc getprotobynumber $proto;
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
