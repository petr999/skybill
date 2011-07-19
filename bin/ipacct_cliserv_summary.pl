#!/usr/bin/perl -w

use strict;
use warnings;

=pod

=head1 NAME

 ipacct_cliserv_summary - script to pass top statistics entries from clients and servers tables to the sliserv_summary table for daily history

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
###
#    DAILY SUMMARY
###
our $sth=$dbh->prepare( "start transaction" );
$sth->execute();
$sth=$dbh->prepare( "delete from ".DB_CLISERV_SUMMARY_TABLE." where day=date( now() )" );
$sth->execute();
$sth=$dbh->prepare( "insert into ".DB_CLISERV_SUMMARY_TABLE." 
	select date_format( now(), '%Y/%m/%d' ), 'clients', sum( bytes) , 
			count( distinct dest ), count( distinct src_port )
		from ".DB_CLIENTS_TABLE." where 
			ts between date_format(now(), '%Y/%m/%d') 
				and date_format(now() + interval 1 day, '%Y/%m/%d') ");
$sth->execute();
$sth=$dbh->prepare( "insert into ".DB_CLISERV_SUMMARY_TABLE." 
	select date_format( now(), '%Y/%m/%d' ), 'servers', sum( bytes) , 
			count( distinct src ), count( distinct dest_port )
		from ".DB_SERVERS_TABLE." where 
			ts between date_format(now(), '%Y/%m/%d') 
				and date_format(now() + interval 1 day, '%Y/%m/%d') ");
$sth->execute();
$sth=$dbh->prepare( "commit" );
$sth->execute();
### CLIENTS DETAILS
$sth=$dbh->prepare( "start transaction" );
$sth->execute();
$sth=$dbh->prepare( "delete from ".DB_CLISERV_SUMMARY_DETAILS_TABLE." where day=date( now( )) and rate_type='clients'" );
$sth->execute();
$sth=$dbh->prepare( "select date_format(now(), '%Y/%m/%d' ) as day, 
												'clients' as rate_type, src as addr, 
								sum(bytes) as acct from ".DB_CLIENTS_TABLE."
								where ts between date_format( now(), '%Y/%m/%d')
								and date_format( now() + interval 1 day, '%Y/%m/%d')
								group by src
								order by acct desc
								limit ".RATES_AMOUNT."
	" );
$sth->execute();
my $hr=$sth->fetchall_hashref('addr');
$sth->finish();
$sth=$dbh->prepare( "select	'clients' as rate_type, src_port as port, 
								date_format(now(), '%Y/%m/%d' ) as day,
								proto,  proto*src_port as hkey,
							  sum(bytes) as ports_acct from ".DB_CLIENTS_TABLE."
								where ts between date_format( now(), '%Y/%m/%d')
								and date_format( now() + interval 1 day, '%Y/%m/%d')
								group by proto, port
								order by ports_acct desc
								limit ".RATES_AMOUNT."
	" );
$sth->execute();
my $hpr=$sth->fetchall_hashref('hkey');
#	use Data::Dumper; print Dumper $hr, $hpr;
while( ( my ($addr, $hrow_ref) =each %$hr ) || ( my ( $proto_port, $hrow_ports_ref )=each %$hpr )  ){
	if(  ( defined( $hrow_ref ) ) && ( my ( $proto_port, $hrow_ports_ref )=each %$hpr ) ){
		$$hrow_ref{port}=$$hrow_ports_ref{port};
		$$hrow_ref{proto}=$$hrow_ports_ref{proto};
		$$hrow_ref{ports_acct}=$$hrow_ports_ref{ports_acct};
	} else {
		#print "PORTS", $hrow_ports_ref, "\n";
			$hrow_ref=$hrow_ports_ref;
			$addr=0;
			$$hrow_ref{bytes}=0;
	}
#	print "$addr: ",  "\n";
}
#while( my $hrow_ports_ref=$sth->fetchrow_hashref() ){
#	$$hr{ $$hrow_ports_ref{hkey} }={ ports_acct=>$$hrow_ports_ref{ports_acct},
#			day=>$$hrow_ports_ref{day},	
#			port=>$$hrow_ports_ref{port},
#			acct=>0,
#			proto=>$$hrow_ports_ref{proto},
#			rate_type=>'servers',
#			addr=>0
#	 };
#}
$sth=$dbh->prepare( "insert into ".DB_CLISERV_SUMMARY_DETAILS_TABLE."
		( day, rate_type, addr, proto, port, bytes, ports_bytes )
			values
		( ?, ?, ?, ?, ?, ?, ? )
	" );
while( (my $addr, my $hrow_ref) =each( %$hr ) ){
	my( $acct, $proto, $ports_bytes, $day, $rate_type, $port, $addr ) = values %$hrow_ref;
	# print "clients: ". join ':', %$hrow_ref; print "\n";
	$sth->execute( $day, 'clients', $addr, $proto, $port, $acct, $ports_bytes);
}
$sth=$dbh->prepare( "commit" );
$sth->execute() or die $dbh->errstr;
### SERVERS DETAILS
$sth=$dbh->prepare( "start transaction" );
$sth->execute() or die $dbh->errstr;
$sth=$dbh->prepare( "delete from ".DB_CLISERV_SUMMARY_DETAILS_TABLE." where day=date( now() ) and rate_type='servers'" );
$sth->execute() or die $dbh->errstr;
$sth=$dbh->prepare( "select date_format(now(), '%Y/%m/%d' ) as day, 
								'servers' as rate_type, dest as addr, 
								sum(bytes) as acct from ".DB_SERVERS_TABLE."
								where ts between date_format( now(), '%Y/%m/%d')
								and date_format( now() + interval 1 day, '%Y/%m/%d')
								group by dest
								order by acct desc
								limit ".RATES_AMOUNT."
	" );
$sth->execute() or die $dbh->errstr;
$hr=$sth->fetchall_hashref('addr');
$sth=$dbh->prepare( "select	'servers' as rate_type, dest_port as port, 
								proto, concat( proto,dest_port ) as hkey,
								date_format(now(), '%Y/%m/%d') as day,
								sum(bytes) as ports_acct from ".DB_SERVERS_TABLE."
								where ts between date_format( now(), '%Y/%m/%d')
								and date_format( now() + interval 1 day, '%Y/%m/%d')
								group by proto, port
								order by ports_acct desc
								limit ".RATES_AMOUNT."
	" );
$sth->execute() or die $dbh->errstr;
my( $addr_count, $ports_count ) = ( scalar keys %$hr, $sth->rows );
for( my $i = 0; ( $i < $addr_count ) or ( $i < $ports_count ); $i ++ ){
#while( ( ) || ( ) ){
	my ( $addr, $hrow_ref) = each %$hr;
	my $hrow_ports_ref;
	$hrow_ports_ref=$sth->fetchrow_hashref() if $i< $ports_count;
	if(  defined( $addr ) ){
	  if(  defined $hrow_ports_ref  ){
			$$hrow_ref{port}=$$hrow_ports_ref{port};
			$$hrow_ref{proto}=$$hrow_ports_ref{proto};
			$$hrow_ref{ports_acct}=$$hrow_ports_ref{ports_acct};
		} else {
			$$hrow_ref{port}=0;
			$$hrow_ref{proto}='igmp';
			$$hrow_ref{ports_acct}=0;
		}
	} else {
	  if(  defined $hrow_ports_ref  ){
			my $day = [ localtime ];
            my $year = $$day[5] + 1900;
            $day = join '/', $year, map { $day->[ $_ ];  } reverse ( 3..4 );
			$hrow_ref = { acct => 0, day => $day, rate_type => 'servers', addr => 0, };
			$$hrow_ref{port}=$$hrow_ports_ref{port};
			$$hrow_ref{proto}=$$hrow_ports_ref{proto};
			$$hrow_ref{ports_acct}=$$hrow_ports_ref{ports_acct};
			$hr->{ $i } = $hrow_ref;
		} else {
		}
	}
}
#while( my $hrow_ports_ref=$sth->fetchrow_hashref() ){
#	$$hr{ $$hrow_ports_ref{hkey} }={ ports_acct=>$$hrow_ports_ref{ports_acct},
#			day=>$$hrow_ports_ref{day},	
#			port=>$$hrow_ports_ref{port},
#			acct=>0,
#			proto=>$$hrow_ports_ref{proto},
#			rate_type=>'servers',
#			addr=>0
#	 };
#}
while( (my $addr, my $hrow_ref) =each( %$hr ) ){
	#print "$addr: ", (join ':', %$hrow_ref), "\n";
}
my $sql="insert into ".DB_CLISERV_SUMMARY_DETAILS_TABLE."
		( day, rate_type, addr, proto, port, bytes, ports_bytes )
			values
		( ?, ?, ?, ?, ?, ?, ? )
	";
$sth=$dbh->prepare( $sql );
while( (my $addr, my $hrow_ref) =each( %$hr ) ){
	my( $acct, $proto, $ports_bytes, $day, $rate_type, $port, $addr ) = map { $hrow_ref->{ $_ } }
			qw/acct proto ports_acct day rate_type port addr/
	;
	# print join ':', %$hrow_ref; print "\n";
	$sth->execute( $day, $rate_type, $addr, $proto, $port, $acct, $ports_bytes);
}
$sth=$dbh->prepare( "commit" );
$sth->execute();
###
#    MONTHLY SUMMARY
###
$dbh->do( 'start transaction' );
$dbh->prepare( 'delete from '.DB_DESTSRC_SUMMARY_TABLE.' where month=month( now() ) and year=year( now() )' );
$sth->execute;
$dbh->do( 'commit' );
$dbh->disconnect;
