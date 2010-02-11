#!/usr/bin/perl -w

use strict;
use warnings;

=pod

=head1 NAME

 ipacct_cliserv - script to pass statistics from raw table to the clients and servers tables accoring by the traffic's purpose.

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


our $dbh=DBI->connect("DBI:mysql:database=".DB_NAME.";mysql_socket=".DB_SOCK,DB_USER,DB_PASS);
transactize( "delete from ".DB_CLIENTS_TABLE." where ts>date_format( now(), '%Y/%m/%d')",
	"insert into ".DB_CLIENTS_TABLE." select max( ts ) as ts_max,
	dest, src, 
	if( inet_ntoa( src ) in ( '".(join "','", @{(SERVERS_LIST)})."'  ),
		dest_port, src_port
	), proto, sum( bytes ) as acct from ".DB_RAW_TABLE." 
	where ts>date_format( now(), '%Y/%m/%d' ) and
	(
		(   inet_ntoa( src ) in ( '".(join "','", @{(SERVERS_LIST)})."'  )
			and src_port not in ( ".(join ',', @{(SERVERS_PORTEXCLUDE_LIST)})." )
		)
	  or (  inet_ntoa( dest ) in ( '".(join "','", @{(SERVERS_LIST)})."' ) 
		and dest_port not in ( ".(join ',', @{(SERVERS_PORTEXCLUDE_LIST)})." )
	     )
	)
	group by date_format( ts, '%Y/%m/%d' ), dest, src, if( inet_ntoa( src ) in ( '".(join "','", @{(SERVERS_LIST)})."'  ),
                dest_port, src_port
        ), proto
	-- on duplicate key update bytes=bytes+bytes
	" );
transactize( "delete from ".DB_SERVERS_TABLE." where ts>date_format( now(), '%Y/%m/%d')",
	"insert into ".DB_SERVERS_TABLE." select max( ts ) as ts_max, 
	dest, 
	if(  inet_ntoa( src ) in ( '".(join "','", @{(SERVERS_LIST)})."'  ),
		src_port, dest_port
	), src, proto, sum( bytes ) as acct from ".DB_RAW_TABLE." 
	where ts > date_format(now(), '%Y/%m/%d' ) and
	(
		(   inet_ntoa( src ) in ( '".(join "','", @{(SERVERS_LIST)})."'  )
			and src_port in ( ".(join ',', @{(SERVERS_PORTEXCLUDE_LIST)})." )
		)
	  or (  inet_ntoa( dest ) in ( '".(join "','", @{(SERVERS_LIST)})."' ) 
		and dest_port in ( ".(join ',', @{(SERVERS_PORTEXCLUDE_LIST)})." )
	     )
	)
	group by date_format( ts, '%Y/%m/%d' ), dest, src, if( inet_ntoa( src ) in ( '".(join "','", @{(SERVERS_LIST)})."'  ),
                src_port, dest_port
        ), proto
	order by ts_max desc
	-- on duplicate key update bytes=bytes+bytes
	" );

sub transactize{
	my ( $sql1, $sql2 )=@_;
	$dbh->do( "start transaction" );
	#	print "$sql2\n";
	$dbh->do( $sql1 ); $dbh->do( $sql2 );
	$dbh->do( "commit" );
}

#while( my $href = $sth->fetchrow_hashref() ){
#	print "dest: $$href{dest}, src_port: $$href{src_port}, ts: $$href{ts_max}\n";
#	my $client_sth=$dbh->prepare( "select max( ts ) from ".DB_CLIENTS_TABLE." 
#	where ts between date_format( ? , '%Y/%m/%d' )  and date_format( ?, '%Y/%m/%d' ) + interval 1 day
#		and dest=? and src=? and src_port=? and proto=?
#	" );
#	$client_sth->execute( $$href{ts_max}, $$href{ts_max}, $$href{dest}, $$href{src}, $$href{src_port}, $$href{proto} )
#		 or die('No faith to get the clients');
#	my ( $client_max_ts ) =  $client_sth->fetchrow_array();
#	if ( defined( $client_max_ts ) ){
#	  if ( $client_max_ts ne $$href{ts_max} ){
#		#print "CLIENT_MAX_TS: $client_max_ts\tTS_MAX: $$href{ts_max}\n";
#		my $raw_stat_sth=$dbh->prepare("
#			select sum( bytes) as bytes, max(ts) as ts_max
#				from ".DB_RAW_TABLE."
#				where ts>?
#				and ts between date_format( ?, '%Y/%m/%d' ) and date_format( ?, '%Y/%m/%d' )
#					+ interval 1 day
#				and dest=? and src=? and src_port=? and proto=?
#		" );
#		$raw_stat_sth->execute(  $client_max_ts, $client_max_ts, $client_max_ts, $$href{dest},
#				 $$href{src}, $$href{src_port}, $$href{proto} ) || die 'No faith get raw!';
#		my ( $raw_stat_bytes, $raw_max_ts ) = $raw_stat_sth->fetchrow_array();
#		if( defined($raw_stat_bytes) ){
#			#print "UPDATE BYTES: $raw_stat_bytes\n";
#			my $client_stat_sth=$dbh->prepare( "update ".DB_CLIENTS_TABLE." set ts= ?, bytes=bytes+ ? 
#				where ts=?
#				and dest=? and src=? and src_port=? and proto=?
#			" );
#			$client_stat_sth->execute( $raw_max_ts, $raw_stat_bytes,
#				$client_max_ts, $$href{dest}, $$href{src},
#				$$href{ src_port }, $$href{ proto }
#			) or die "No faith updating clients!";
#		} 
#		$raw_stat_sth->finish;
#	  }
#	} else {
#		my $client_stat_sth=$dbh->prepare( "insert into ".DB_CLIENTS_TABLE." (ts, dest, src, src_port, proto, bytes )
#			values( ?, ?, ?, ?, ?, ? )
#		" );
#		$client_stat_sth->execute( $$href{ ts_max }, $$href{dest}, $$href{ src }, 
#			$$href{ src_port }, $$href{ proto }, $$href{ bytes }
#		) || die "No faith inserting clients!";
#	#	print "NEW: $$href{dest}\n";
#	}
#	$client_sth->finish();
#}
#$sth->finish();
#$sth=$dbh->prepare( "select max( ts ) as ts_max, date_format( ts, '%Y/%m/%d' ) as  ts_day,
#	dest, src, dest_port, proto, sum( bytes ) as bytes from ".DB_RAW_TABLE." 
#	where ts > from_unixtime( unix_timestamp( now() ) - ".DB_CLISERV_PERIOD .")
#	and inet_ntoa( dest ) in ( ".(join ',', @{(SERVERS_LIST)})." ) 
#	and src_port not in ( ".(join ',', @{(SERVERS_PORTEXCLUDE_LIST)})." )
#	group by date_format( ts, '%Y/%m/%d' ), dest, src, dest_port, proto
#	order by ts_max desc
#	" );
#$sth->execute();
#while( my $href = $sth->fetchrow_hashref() ){
##	print "dest: $$href{dest}, dest_port: $$href{dest_port}, src: $$href{src}, ts: $$href{ts_max}\n";
#	my $servers_sth=$dbh->prepare("select max( ts ) as ts_max from ".DB_SERVERS_TABLE."
#		where ts between date_format( ?, '%Y/%m/%d' ) 
#			and date_format( (? + interval 1 day), '%Y/%m/%d')
#		and dest=? and src=? and dest_port=? and proto=?
#	");
#	$servers_sth->execute( $$href{ts_max}, $$href{ts_max}, $$href{dest}, $$href{src}, 
#		$$href{dest_port}, $$href{proto} );
#	my ( $servers_ts_max )=$servers_sth->fetchrow_array() ;
#	$servers_sth->finish();
#	if( defined ( $servers_ts_max ) ){
##		print "FOUND: $servers_ts_max\n";
#		if( $$href{ts_max} ne $servers_ts_max ){
#			my $servers_stat_sth=$dbh->prepare( "select sum( bytes ), max(ts) as ts_max from ".DB_RAW_TABLE."
#				where ts>? and ts between date_format( ?, '%Y/%m/%d' )
#						and date_format( ?, '%Y/%m/%d' )
#				  and src_port!=53
#				  and dest=? and dest_port=? and src=? and proto=?
#				" );
#			$servers_stat_sth->execute( $servers_ts_max, $servers_ts_max, $servers_ts_max, $$href{dest}, $$href{dest_port},
#				$$href{src}, $$href{proto}
#			);
#			my( $bytes, $raw_ts_max ) = $servers_stat_sth->fetchrow_array();
#			$servers_stat_sth->finish();
#			$servers_stat_sth=$dbh->prepare(" update servers set ts=?, bytes=bytes+?
#				where ts between date_format( ?, '%Y/%m/%d' )
#					and date_format( ?+interval 1 day , '%Y/%d/%m' )
#				and dest=? and dest_port=? and proto=?
#			");
#			$servers_stat_sth->execute( $raw_ts_max, $bytes, $$href{ ts_max },
#				$$href{ts_max}, $$href{dest}, $$href{dest_port}, $$href{proto}
#			) || die "No faith updating servers!\n";
#			$servers_stat_sth->finish;
#		}
#	} else {
##		print "NOT FOUND\n";
#		my $servers_stat_sth=$dbh->prepare( "insert into ".DB_SERVERS_TABLE." 
#			( ts, dest, dest_port, src, proto, bytes )
#			values ( ?, ?, ?, ?, ?, ? )
#		" );
#		$servers_stat_sth->execute( $$href{ts_max}, $$href{dest}, $$href{dest_port}, 
#			$$href{src}, $$href{proto}, $$href{bytes} 
#		) || die "No faith to insert servers!";
#		$servers_stat_sth->finish();
#	}
#}
#$sth->finish();
$dbh->disconnect;

