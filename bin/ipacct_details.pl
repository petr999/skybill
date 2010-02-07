#!/usr/bin/perl -w

use strict;
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

### DAILY DETAILS
our $clients_sth=$dbh->prepare( "select dest, src, sum( bytes ) as bytes from ".DB_CLIENTS_TABLE." 
	where ts between date_format( now(), '%Y/%m/%d' ) and date_format( now() + interval 1 day, '%Y/%m/%d' )
	group by date_format( ts, '%Y/%m/%d' ), dest, src
	" );
$clients_sth->execute();
our $servers_sth=$dbh->prepare( "select dest, src, sum( bytes ) as bytes from ".DB_SERVERS_TABLE." 
	where ts between date_format( now(), '%Y/%m/%d' ) and date_format( now() + interval 1 day, '%Y/%m/%d' )
	group by date_format( ts, '%Y/%m/%d' ), dest, src
	" );
$servers_sth->execute();
$clients_sth->execute();
our $clients_ref=$clients_sth->fetchall_hashref( [ qw/dest src/ ] );
our $servers_ref=$servers_sth->fetchall_hashref( [ qw/dest src/ ] );
our $time = time;

$dbh->do("start transaction" );
$dbh->do("delete from details_daily where day=date( now() )" );
#print "CLIENTS REF: ".@$clients_ref."\n";
foreach my $dest ( keys %$servers_ref ){
	foreach my $src ( keys %{$servers_ref->{ $dest } } ){
		if( defined $clients_ref->{ $dest }->{ $src } ){
			$servers_ref->{ $dest }->{ $src }->{ bytes } += $clients_ref->{ $dest }->{ $src }->{ bytes };
			delete $clients_ref->{ $dest }->{ $src };
		}
	#my $clients_ref_count=@$clients_ref;
#	foreach my $j ( 0..($clients_ref_count-1) ){
#		my $i=$clients_ref_count-$j-1;
#		#print "COUNT: $clients_ref_count \t I: $i\t", $$clients_ref[$i][0], "\t", $$servers_row_ref[0], "\t",  $$clients_ref[$i][1], "\t", $$servers_row_ref[1],"\n";
#		if( defined($$clients_ref[$i]) and $$clients_ref[$i][0]==$$servers_row_ref[0]
#					and $$clients_ref[$i][1]==$$servers_row_ref[1] )
#		{
#			$$servers_row_ref[2]+=$$clients_ref[$i][2];
#			delete @$clients_ref[$i];
#		}
#	}
		$dbh->do( "insert into ".DB_DETAILS_TABLE." (day, dest, src, bytes )
			values( now(), ".$dest.", ".$src.", ".$servers_ref->{ $dest }->{ $src }->{ bytes }." )
		" );
	}
}
#print "daily servers insert: ".( time - $time )."\n";
foreach my $dest ( keys %$clients_ref ){
	foreach my $src( keys %{ $clients_ref->{ $dest } } ){
		$dbh->do( "insert into ".DB_DETAILS_TABLE." (day, dest, src, bytes )
			values( now(), ".$dest.", ".$src.", ".$clients_ref->{ $dest }->{ $src }->{ bytes }." )
		" );
	}
}

$dbh->do("commit" );

#while( my( $dest, $src, $bytes ) = $clients_sth->fetchrow_array() ){
#	my @deleted_servers_ref=();
#	foreach my $i ( 0..$#{@$servers_ref} ){
#		my $rate_ref=$$servers_ref[$i];
#		print "I: $i", @$rate_ref, "\n";
#		if( $$rate_ref[0]==$dest and $$rate_ref[1]==$src ){
#			$bytes+=$$_[2];
#			push @deleted_servers_ref, $i ;
#		}
#	}
#	foreach( sort { $b cmp $a } @deleted_servers_ref ){
#		delete $$servers_ref[ $_ ];
#	}
#	my $details_sth=$dbh->prepare( "select bytes from ".DB_DETAILS_TABLE."
#		where dest=? and src=? and day=now() 
#	" );
#	$details_sth->execute( $dest, $src );
#	my( $details_bytes ) = $details_sth->fetchrow_array();
#	$details_sth->finish();
#	if( defined( $details_bytes ) ){
#		$details_sth=$dbh->prepare( "update ".DB_DETAILS_TABLE." set bytes=?
#			where day=now() and dest=? and src=?
#		" );
#		$details_sth->execute( $bytes, $dest, $src ) || die "No faith updating details";
#	} else {
#		$details_sth=$dbh->prepare( "insert into ".DB_DETAILS_TABLE." (day, dest, src, bytes )
#			values( now(), ?, ?, ? )
#		" );
#		$details_sth->execute( $dest, $src, $bytes ) || die "No faith inserting details";
#	}
#}

$clients_sth->finish();
$servers_sth->finish();

#print "daily: ".( time - $time )."\n";

### MONTHLY DETAILS
$time = time;
$dbh->do("start transaction");
$dbh->do("delete from ".DB_DETAILS_MONTHLY_TABLE." where year=year( now() ) and month=month( now() )" );
$dbh->do("insert into ".DB_DETAILS_MONTHLY_TABLE." select year(day), month(day), dest, 'dest' as kind, sum(bytes) as acct
		from ".DB_DETAILS_TABLE." where day between date_format( now(), '%Y/%m/01' )
				and date_format( ( now() +interval 1 month ), '%Y/%m/01' )
		group by dest order by acct desc
	");
$dbh->do("insert into ".DB_DETAILS_MONTHLY_TABLE." select year(day), month(day), src, 'src' as kind, sum(bytes) as acct
		from ".DB_DETAILS_TABLE." where day between date_format( now(), '%Y/%m/01' )
				and date_format( ( now() +interval 1 month ), '%Y/%m/01' )
		group by src order by acct desc
	");
$dbh->do("commit");
#print "monthly: ".( time - $time )."\n";

$dbh->disconnect;

