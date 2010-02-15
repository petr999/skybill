#!/usr/bin/perl -w

package Skybill;

=pod

=head1 NAME

 Skybill - main package of the Skybill program, yet holds only the web interface stuff

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

use strict;
use warnings;

use CGI::Carp qw/fatalsToBrowser/;
use XML::LibXSLT;
use XML::LibXML;
use Skybill::XML::Element;
use DBI;
use CGI qw/Vars/;
use POSIX qw/strftime setlocale LC_COLLATE LC_CTYPE LC_TIME/;
use Time::HiRes qw/time/;
use Time::ParseDate;
use Validate::Net;

use Storable qw( store retrieve ); # used to save/restore the internal data
use LockFile::Simple qw( lock unlock ); # used to lock the data file

use Cwd qw/realpath getcwd/;

use Skybill::Config;

use constant CONTENTS_AMOUNT=>20;
use constant Q_KEYS=>[ 'q',	#kind of query
		'p', 										# page of query
		'my', 									# month-year
		'd', 										# day
		'dst',									# destination IP
		'src',									# source IP
		'prt',										# port-protocol
		'ft'										# forming time
	];
use constant Q_TYPES=>[ 'sm',	#sources per month
		'dm',											#destinations per month
		'dd',											#destinations per day
		'sd',											#sources per day
		'pd',											#ports per day
		'ds',											#daily summary
		'da',											#daily addresses
		'ms'											#monthly summary
	];
use constant Q_REGEXES=>{ 'p'		=>'\d+',
													'my'	=>'\d{4}-\d{1,2}',
													'd'		=>'\d{2}',
													'dst'	=>'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}',
													'src'	=>'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}',
													'prt'	=>'\d{1,5}-(tcp|udp|icmp|igmp)',
													'ft'  =>'1'
	};


my $locale = ( 'ru' eq lc $ENV{ COUNTRY_CODE } )
	? 'ru_RU.UTF-8'
	: 'en_US.UTF-8'
;
setlocale( LC_COLLATE, 	$locale );
setlocale( LC_CTYPE, 		$locale );
setlocale( LC_TIME, 		$locale );
use locale;

my $dbh = undef;
my $query = undef;

my $parser = XML::LibXML->new();
my $xslt = XML::LibXSLT->new();

my( $month_condition, $year_condition, $day_condition, $src_condition, $dst_condition ) = map { '' } (0..4);

sub new{
	my $class = shift;
	my $country_code = country_code();
	my $xsl_path = realpath( "$main::skybill_lib/../tmpl/$country_code" );
	my $hash = { xsl_path => $xsl_path,
	};
	bless $hash, $class;
}

sub page{ 
	print CGI->header( -charset => 'utf-8' );
  my $q=new CGI;
  $query=$q->Vars;
  filter_query( $query );
	$dbh=DBI->connect("DBI:mysql:database=".DB_NAME.";mysql_socket=".DB_SOCK,DB_USER,DB_PASS);
  my $bill=get_bill( $query );
  $dbh->disconnect();

  if( $bill == 0 ){
  	say_err();
  } else {
		my $self=__PACKAGE__->new;
  	$self->say_bill( $bill );
  }
}


### SUBS ###
sub get_bill{
	my $query=shift @_;
	my $bill_time=time();

	my( $year, $month, $day, $dst, $src );
	if( defined $query->{my} ){
		( $year, $month )=split '-', $query->{my};
	}
	if( defined $query->{d} ){
		 $day =$query->{d};
	}
	if( defined $query->{dst} ){
		$dst=$query->{dst};
	}
	if( defined $query->{src} ){
		$src=$query->{src};
	}
	
	$month_condition="between ".( defined($query->{'my'})?
			"$year$month"."01 and ( $year$month"."01 + interval 1 month -interval 1 day )"
			:"date_format( now(), '%Y%m01' ) and date_format( now() + interval 1 month - interval 1 day, '%Y%m01' )"
	);
	$year_condition="between ".( defined($query->{'my'})?
			"$year"."0101 and ( $year"."0101 + interval 1 year )"
			:"date_format( now(), '%Y0101' ) and date_format( now() + interval 1 year, '%Y0101' )"
	);
	$day_condition=( defined( $query->{'my'} ) && defined( $query->{d} ) )
		?" between '$year/$month/$day' and ( '$year/$month/$day' + interval 1 day )"
		:" between date( now() ) and date( now() + interval 1 day ) ";
	$dst_condition=$dst?"=inet_aton('$dst')":">0";
	$src_condition=$src?"=inet_aton('$src')":">0";

	my $bill=XML::LibXML::Document->new('1.0', 'UTF8');
	my $parent=Skybill::XML::Element->new('bill');
	$bill->setDocumentElement($parent);
	my $sibling=Skybill::XML::Element->new('yesterday');
	get_bill_day( $sibling, " date( now() - interval 1 day ) " ) || return 0;
	$parent->addChild( $sibling );
	get_content( $query, $bill );
	$sibling=Skybill::XML::Element->new('today');
	get_bill_day( $sibling, ' date( now() ) ' ) || return 0;
	$parent->addChild( $sibling );
	$sibling=get_bill_head( ) || return 0;
	$parent->addChild( $sibling );
	$parent->setAttribute( 'forming-time', time()-$bill_time );
	#print $bill->toString(2);
	return $bill;
}

sub get_content{
	my ($href, $bill )= @_;
	my $parent=$bill->getDocumentElement;
	my $sibling=get_query_element( $query );
	my $sth;
	my $bill_time=time();
	my $q=$query->{q};
	my $sql;
	my( $year, $month )=split( '-', $query->{my} ) if grep /^my$/, keys %$query;

	$parent->addChild( $sibling );
	$sibling=Skybill::XML::Element->new('content');
	$parent->addChild( $sibling );
	$parent=$sibling;
	my $content=$parent;
	my $page=( ( grep /^p$/, keys %$query ) && defined( $query->{p} ) )? $query->{p}: 0;
	#DAILY DESTS
	if( ( ( grep /^q$/, keys %$query ) &&  ( grep /^$q$/, ( 'dd', 'ds' ) ) && ( !defined( $query->{dst} ) ) ) ||
				( !grep /^q$/, keys %$query )  ){
		$sql="select count( distinct dest ) from details_daily
					where day $day_condition
			 			and src $src_condition 
				";
		$sth=$dbh->prepare( $sql );
		$sth->execute() or die $!;
		my( $count )=$sth->fetchrow_array();
		$sth=$dbh->prepare( "select inet_ntoa(dest), sum(bytes) as acct
									from details_daily
			where day $day_condition
				and src $src_condition
			group by dest
			order by acct desc
			limit ".$page*CONTENTS_AMOUNT.",".CONTENTS_AMOUNT."
			-- limit 10
		" );
		$sth->execute();
		$sibling=Skybill::XML::Element->new('daily-dests');
		$content->addChild( $sibling );
		$parent=$sibling;
		while( my( $ip, $bytes )=$sth->fetchrow_array() ){
			$sibling=Skybill::XML::Element->new('rate');
			$sibling->setAttribute( 'ip', $ip );
			$sibling->setAttribute( 'bytes', $bytes );
			$sibling->setAttribute( 'href', href_chart( $query, { dst=>$ip, q=>'sd' } ) );
			$parent->addChild( $sibling );
		}
		$parent->setAttribute( 'href-nosrc', href_chart( $query, { src=>'', q=>'dd'  }) ) if defined( $query->{src} );
		page_chart( $parent, $count );
	}
	#MONTHLY DESTS
	if( ( ( grep /^q$/, keys %$query ) &&  ( grep /^$q$/, ( 'ms', 'dm' ) ) && ( !defined $query->{dst} ) ) ||
				( !grep /^q$/, keys %$query )  ){
		$sql="select count( distinct dest ) from details_daily
					where day $month_condition
			".(
				defined( $query->{src} ) ? " and src $src_condition " : ""
			);
		$sth=$dbh->prepare( $sql );
		$sth->execute() or die $!;
		my( $count )=$sth->fetchrow_array();
		$sql=defined( $query->{src} )?"select inet_ntoa(dest), sum(bytes) as acct from details_daily
				where src $src_condition
				and day $month_condition
				group by dest
				order by acct desc
				limit ".$page*CONTENTS_AMOUNT.",".CONTENTS_AMOUNT."
			"
			:"select inet_ntoa(ip), bytes from details_monthly
			where month=".( $month?$month: "month( now() )" )." and year=".( $year?$year: "year( now() )" )."
				and kind='dest'
			order by bytes desc
			limit ".$page*CONTENTS_AMOUNT.",".CONTENTS_AMOUNT."
			-- limit 10
		" ;
		$sth=$dbh->prepare( $sql ) or die $!;
		$sth->execute();
		$sibling=Skybill::XML::Element->new('monthly-dests');
		$content->addChild( $sibling );
		$parent=$sibling;
		while( my( $ip, $bytes )=$sth->fetchrow_array() ){
			$sibling=Skybill::XML::Element->new('rate');
			$sibling->setAttribute( 'ip', $ip );
			$sibling->setAttribute( 'bytes', $bytes );
			$sibling->setAttribute( 'href', href_chart( $query, { dst=>$ip, q=>'ms'  } ) );
			$parent->addChild( $sibling );
		}
		$parent->setAttribute( 'href-nosrc', href_chart( $query, { src=>'', q=>'ms'  }) ) if defined( $query->{src} );
		page_chart( $parent, $count );
	}
	#DAILY ADDRESSES
	if( ( ( grep /^q$/, keys %$query ) &&  ( grep /^$q$/, ( 'da', 'ds' ) ) && ( not defined $query->{dst} )
				&& ( not defined $query->{src} )
			) ||
				( !grep /^q$/, keys %$query )  ){
		#my $qdd=( ( grep /^q$/, keys %$query ) &&  ( $query->{q} eq 'dd' )   )?1:0;
		#my $page=( ( grep /^p$/, keys %$query ) && defined( $query->{p} ) && $qdd )? $query->{p}: 0;
		$sibling=Skybill::XML::Element->new('daily-addresses');
		$content->addChild( $sibling );
		$parent=$sibling;
		$sth=$dbh->prepare( "select count( distinct dest*src ) from details_daily
			where day $day_condition
		" );
		$sth->execute();
		my( $count )=$sth->fetchrow_array();
		$sth=$dbh->prepare( "select inet_ntoa(dest), inet_ntoa(src), sum( bytes ) from details_daily
			where day $day_condition
			group by dest, src order by bytes desc limit ".$page*CONTENTS_AMOUNT.",".CONTENTS_AMOUNT."
		" );
		$sth->execute() or die $!;
		while( my( $dest, $src, $bytes ) = $sth->fetchrow_array ){
			$sibling=Skybill::XML::Element->new('fromto');
			$sibling->setAttribute( 'dest', $dest );
			$sibling->setAttribute( 'src', $src );
			$sibling->setAttribute( 'bytes', $bytes );
			$sibling->setAttribute( 'href', href_chart( $query, { dst=>$dest, src=>$src, q=>'pd' } ) );
			#$sibling->setAttribute( 'src-whois-href', whois_href( $src ) );
			$parent->addChild( $sibling );
		}
		page_chart( $parent, $count );
	}
	#DAILY PORTS
	if(  ( grep /^q$/, keys %$query ) &&  ( grep /^$q$/, ( 'pd', 'dd', 'ds', 'sd' ) ) && defined(  $query->{dst} ) && defined( $query->{src} )
			 ){
		#my $qdd=( ( grep /^q$/, keys %$query ) &&  ( $query->{q} eq 'dd' )   )?1:0;
		#my $page=( ( grep /^p$/, keys %$query ) && defined( $query->{p} ) && $qdd )? $query->{p}: 0;
		$sibling=Skybill::XML::Element->new('daily-ports');
		$content->addChild( $sibling );
		$parent=$sibling;
#		$sth=$dbh->prepare( "select count( distinct dest_port*src_port ) from raw
#			where ts=$day_condition and dest $dst_condition and src $src_condition
#		" );
#		$sth->execute();
#		my( $count )=$sth->fetchrow_array();
		$sql="select dest_port, src_port, proto, sum( bytes ) as acct  from raw
			where ts between date_format( $day_condition, '%Y%m%d' ) and date_format( ( $day_condition +interval 1 day ), '%Y%m%d' )
				and dest $dst_condition and src $src_condition
			group by src_port, dest_port, proto order by acct desc
		";
		#print "SQL: $sql\n";
		$sth=$dbh->prepare( $sql );
		$sth->execute() or die $!;
		while( my( $dest_port, $src_port, $proto,  $bytes ) = $sth->fetchrow_array ){
			my ($dest_serv )=getservbyport $dest_port, $proto;
			my ($src_serv )=getservbyport $src_port, $proto;
			$sibling=Skybill::XML::Element->new('fromto');
			$sibling->setAttribute( 'dest_port', $dest_port.$proto.($dest_serv?"/($dest_serv)":'') );
			$sibling->setAttribute( 'bytes', $bytes );
			$sibling->setAttribute( 'src_port', $src_port.$proto.($src_serv?"/($src_serv)":'') );
			$parent->addChild( $sibling );
		}
		#page_chart( $parent, $count );
	}
	#DAILY SOURCES
	if( ( ( grep /^q$/, keys %$query ) &&  ( grep /^$q$/, ( 'sd', 'ds' ) ) && ( !defined $query->{src} )   ) ||
				( !grep /^q$/, keys %$query )  ){
		$sth=$dbh->prepare( "select count( distinct src ) from details_daily
			where day $day_condition
				and dest $dst_condition
		" );
		$sth->execute();
		my( $count )=$sth->fetchrow_array();
		$sth=$dbh->prepare( "select inet_ntoa(src), sum(bytes) as acct
									from details_daily
			where day $day_condition
				and dest $dst_condition
			group by src
			order by acct desc
			limit ".$page*CONTENTS_AMOUNT.",".CONTENTS_AMOUNT."
			-- limit 10
		" );
		$sth->execute();
		$sibling=Skybill::XML::Element->new('daily-sources');
		$content->addChild( $sibling );
		$parent=$sibling;
		while( my( $ip, $bytes )=$sth->fetchrow_array() ){
			$sibling=Skybill::XML::Element->new('rate');
			$sibling->setAttribute( 'ip', $ip );
			$sibling->setAttribute( 'bytes', $bytes );
			$sibling->setAttribute( 'href', href_chart( $query, { src=>$ip, q=>'dd' } ) );
			$parent->addChild( $sibling );
		}
		$parent->setAttribute( 'href-nodst', href_chart( $query, { dst=>''  }) ) if defined( $query->{dst} );
		page_chart( $parent, $count );
	}
	#MONTHLY SOURCES
	if( ( ( grep /^q$/, keys %$query ) &&  ( grep /^$q$/, ( 'sm', 'ms' ) ) && ( !defined $query->{src} ) ) ||
				( !grep /^q$/, keys %$query )  ){
		#my $qsm=( ( grep /^q$/, keys %$query ) &&  ( $query->{q} eq 'sm' )   )?1:0;
		#print "Q: ", join( ':', %$query ), "\tP: $page\tQSM: $qsm\n";
		$sql = defined( $query->{dst} )?"select count( distinct src ) from details_daily
									where dest $dst_condition
									and day $month_condition
								"
								:"select count( * ) from details_monthly
									where month=".( $month?$month: "month( now() )" )." and year=".( $year?$year: "year( now() )" )."
									and kind='src'
								";
		#print "SQL: $sql\n";
		$sth=$dbh->prepare( $sql ); $sth->execute() or print $!;
		my( $count )=$sth->fetchrow_array();
		my $sql = defined( $query->{dst} )?"select inet_ntoa(src), sum(bytes) as acct from details_daily
														where dest $dst_condition
															and day $month_condition
														group by src
														order by acct desc
														limit ".$page*CONTENTS_AMOUNT.",".CONTENTS_AMOUNT."
													"
													:"select inet_ntoa(ip), bytes from details_monthly
														where month=".( $month?$month: "month( now() )" )."
															and year=".( $year?$year: "year( now() )" )."
															and kind='src'
														order by bytes desc
														limit ".$page*CONTENTS_AMOUNT.",".CONTENTS_AMOUNT."
													";
		$sth=$dbh->prepare( $sql );
		$sth->execute() or print $!;
		$sibling=Skybill::XML::Element->new('monthly-sources');
		$content->addChild( $sibling );
		$parent=$sibling;
		while( my( $ip, $bytes )=$sth->fetchrow_array() ){
			$sibling=Skybill::XML::Element->new('rate');
			$sibling->setAttribute( 'ip', $ip );
			$sibling->setAttribute( 'bytes', $bytes );
			$sibling->setAttribute( 'href', href_chart( $query, { src=>$ip, q=>'dm' } ) );
			$parent->addChild( $sibling );
		}
		$parent->setAttribute( 'href-nodst', href_chart( $query, { dst=>''  }) ) if defined( $query->{dst} );
		page_chart( $parent, $count );
	}
	### DAILY BYTES
	my $day_format = ( 'ru_RU.UTF-8' eq $locale )? '%d/%m/%Y' : '%Y-%m-%d'
	$sql=( defined( $query->{dst} ) or defined( $query->{src} ) )?
		(
			"select date_format( day, '$day_format' ), sum( bytes ) as acct 
				from details_daily where day $month_condition".
					( defined( $dst_condition )?" and dest $dst_condition ":'' ).
					( defined( $src_condition )?" and src $src_condition ":'' ).
			"	group by day
				order by day desc
			"
		)
		:"select date_format( day, '$day_format' ), bytes as acct
								from daily
			where day $month_condition order by day desc
			-- limit 10
		";
	$sth=$dbh->prepare( $sql );
	$sth->execute();
	$sibling=Skybill::XML::Element->new('daily-bytes');
	$content->addChild( $sibling );
	$parent=$sibling;
	my $max_bytes=0;
	while( my( $day, $bytes )=$sth->fetchrow_array() ){
		$max_bytes=$bytes if $bytes>$max_bytes;
		$sibling=Skybill::XML::Element->new('rate');
		$sibling->setAttribute( 'day', $day );
		my( $mday, $month, $year )=split '-', $day;
		$sibling->setAttribute( 'bytes', $bytes );
		$sibling->setAttribute( 'href', href_chart( $query, { my=>"$year-$month", q=>'ds', d=>$mday } ) );
		$parent->addChild( $sibling );
	}
	$parent->setAttribute( 'max-bytes', $max_bytes );
	$parent->setAttribute( 'href-nodst', href_chart( $query, { dst=>'', q=>'ds'  }) ) if defined( $query->{dst} );
	$parent->setAttribute( 'href-nosrc', href_chart( $query, { src=>'', q=>'ds'  }) ) if defined( $query->{src} );
	### MONTHLY BYTES
	$sql=( defined( $query->{dst} ) or defined( $query->{src} ) )?(
			( defined( $query->{src} ) and defined( $query->{dst} ) )?" select year( day ), month( day ), sum(bytes)
					from details_daily where dest $dst_condition and src $src_condition
					group by year(day), month( day )
					order by year( day ) desc, month( day ) desc
				"
			:" select year, month,  bytes from details_monthly
				where ip ".( ( defined $query->{dst} )?$dst_condition:$src_condition )."
				and kind='".( ( defined $query->{dst} )?'dest':'src' )."' order by year desc, month desc
			" 
		):" select year( day ), month( day ), sum( bytes) from daily
		 group by month( day ), year( day ) order by year( day) desc, month( day ) desc
		";
	#print "SQL: $sql\n";
	$sth=$dbh->prepare( $sql );
	$sth->execute();
	$sibling=Skybill::XML::Element->new('monthly-bytes');
	$content->addChild( $sibling );
	$parent=$sibling;
	$max_bytes=0;
	while( my( $year, $month, $bytes )=$sth->fetchrow_array() ){
		$max_bytes=$bytes if $bytes>$max_bytes;
		$sibling=Skybill::XML::Element->new('rate');
		$sibling->setAttribute( 'year', $year );
		$sibling->setAttribute( 'month', sprintf '%02d', $month );
		$sibling->setAttribute( 'bytes', $bytes );
		$sibling->setAttribute( 'href', href_chart( $query, { my=>"$year-$month", q=>'ms',  d=>'' } ) );
		$parent->addChild( $sibling );
	}
	$parent->setAttribute( 'max-bytes', $max_bytes );
	$parent->setAttribute( 'href-nodst', href_chart( $query, { dst=>'', q=>'ms'  }) ) if defined( $query->{dst} );
	$parent->setAttribute( 'href-nosrc', href_chart( $query, { src=>'', q=>'ms'  }) ) if defined( $query->{src} );
	$content->setAttribute( 'forming-time', time()-$bill_time );
}

sub filter_value{
	my ( $href, $name, $value )=@_;
	if( $name eq 'q' ){
		delete $$href{ $name } if not grep { $value eq $_ } @{( Q_TYPES )};
	} else {
		my $regex=Q_REGEXES->{ $name };
		my $checker=Validate::Net->new('fast') if grep /^$name$/, ( 'dst', 'src' );
		grep( /^$regex$/, $value  ) or delete $$href{ $name };
		if( grep /^$name$/, keys %$href ){
			if( $name eq 'my' ){
				my( $year, $month )=split '-', $href->{my};
				delete $href->{my} if not parsedate( "$year/$month/01" );
				$href->{my}="$year-0$month" if length( $month ) == 1;
			} elsif( $name eq 'dst' ){
				my $dst=$href->{dst};
				delete $href->{dst} if not $checker->ip( $dst );
			} elsif( $name eq 'src' ){
				my $src=$href->{src};
				delete $href->{src} if not $checker->ip( $src );
			}
		}
	}
}

sub filter_query{
	my $href = shift @_;
	my $q_keys=Q_KEYS;
	my $q_types=Q_TYPES;
	my $q_regexes=Q_REGEXES;
	my $deleted=[];
	foreach my $name( keys %$href ){
		my $value=$$href{$name};
		if( grep /^$name$/, @$q_keys ) { 
			filter_value( $href, $name, $value);  
		} else {
			delete $$href{$name};
		}
	}
}

sub get_bill_month{
	my( $month_node, $month_condition ) = @_;
	my $sth=$dbh->prepare("select date_format( $month_condition, '%Y' ), date_format( $month_condition, '%m' ),
			sum( bytes ) from daily where month(day)
				between month( $month_condition ) and month ( $month_condition +interval 1 month )
	");
	$sth->execute() || return 0;
	my ( $y, $m, $bytes )= $sth->fetchrow_array();
	$month_node->setAttribute( 'bytes', $bytes );
	my $bill_time=time();
	$sth=$dbh->prepare("select items, bytes, ports from cliserv_summary 
		where day $day_condition
			and rate_type='clients'
	");
	$sth->execute() or die $!;
	( my $clients, $bytes, my $ports )=$sth->fetchrow_array();
	$month_node->setAttribute( 'internal-clients', $clients );
	$month_node->setAttribute( 'internal-bytes', $bytes );
	$month_node->setAttribute( 'internal-ports', $ports );
	$sth=$dbh->prepare("select items, bytes, ports from cliserv_summary 
		where day $day_condition
			 and rate_type='servers'
	");
	$sth->execute() or die $!;
	( my $servers, $bytes, $ports, my $dayfmt )=$sth->fetchrow_array();
	$month_node->setAttribute( 'external-clients', $servers );
	$month_node->setAttribute( 'external-bytes', $bytes );
	$month_node->setAttribute( 'external-ports', $ports );
	$month_node->setAttribute( 'date', $dayfmt );
	$sth=$dbh->prepare( "select rate_type, inet_ntoa( addr ), proto, port,
					bytes as acct, ports_bytes from cliserv_summary_details 
					where day $day_condition
					 order by bytes desc
			" );
	$sth->execute or die $!;
	my $ar=$sth->fetchall_arrayref( );
	my $internals_day_sibling=Skybill::XML::Element->new( 'internals-rating' );
	my $externals_day_sibling=Skybill::XML::Element->new( 'externals-rating' );
	my $internal_ports_day_sibling=Skybill::XML::Element->new( 'internal-ports-rating' );
	my $external_ports_day_sibling=Skybill::XML::Element->new( 'external-ports-rating' );
	$month_node->addChild( $internals_day_sibling );
	$month_node->addChild( $externals_day_sibling );
	$month_node->addChild( $internal_ports_day_sibling );
	$month_node->addChild( $external_ports_day_sibling );
	foreach(@$ar){
		my( $rate_type, $addr, $proto, $port, $bytes, $port_bytes)= @$_;
		my $rate=Skybill::XML::Element->new( 'rate' );
		$rate->setAttribute( 'ip', $addr );
		$rate->setAttribute( 'bytes', $bytes );
		if($rate_type eq 'clients'){
				$internals_day_sibling->addChild( $rate );
				$rate->setAttribute( 'href', href_chart( $query, { q=>'ds', dst=>$addr, src=>'', y=>$y, m=>$m } ) );
		} else {
				$externals_day_sibling->addChild( $rate );
				$rate->setAttribute( 'href', href_chart( $query, { q=>'ds', src=>$addr, dst=>'', y=>$y, m=>$m } ) );
		}
	}
	@$ar=sort  { $$b[5] <=> $$a[5] } @$ar;
	foreach(@$ar){
		my( $rate_type, $addr, $proto, $port, $bytes, $port_bytes)= @$_;
		my $ports_rate=Skybill::XML::Element->new( 'rate' );
		my ($serv )=getservbyport $port, $proto;
		$ports_rate->setAttribute( 'port', $port.'/'.$proto.($serv?"($serv)":'') );
		$ports_rate->setAttribute( 'bytes', $port_bytes );
		if($rate_type eq 'clients'){
			$internal_ports_day_sibling->addChild( $ports_rate ) if $port_bytes != 0;
		} else {
			$external_ports_day_sibling->addChild( $ports_rate ) if $port_bytes!=0;
		}
	}
	$month_node->setAttribute( 'forming-time', time()-$bill_time );
	return 1;
}

sub get_bill_day{
	my( $day_node, $day_condition ) = @_;
	my $sth=$dbh->prepare("select date_format( $day_condition, '%Y-%m' ), date_format( $day_condition, '%d' ),
			bytes from daily 
					where day between ( $day_condition ) and ( $day_condition + interval 1 day - interval 1 second )
	");
	$sth->execute() || return 0;
	my ( $my, $d, $bytes )= $sth->fetchrow_array();
	$day_node->setAttribute( 'bytes', $bytes );
	my $bill_time=time();
	$sth=$dbh->prepare("select items, bytes, ports from cliserv_summary 
					where day between ( $day_condition ) and ( $day_condition + interval 1 day - interval 1 second )
		and rate_type='clients'
	");
	$sth->execute() or die $!;
	( my $clients, $bytes, my $ports )=$sth->fetchrow_array();
	$day_node->setAttribute( 'internal-clients', $clients );
	$day_node->setAttribute( 'internal-bytes', $bytes );
	$day_node->setAttribute( 'internal-ports', $ports );
	$sth=$dbh->prepare("select items, bytes, ports from cliserv_summary 
					where day between ( $day_condition ) and ( $day_condition + interval 1 day - interval 1 second )
		and rate_type='servers'
	");
	$sth->execute() or die $!;
	( my $servers, $bytes, $ports, my $dayfmt )=$sth->fetchrow_array();
	$day_node->setAttribute( 'external-clients', $servers );
	$day_node->setAttribute( 'external-bytes', $bytes );
	$day_node->setAttribute( 'external-ports', $ports );
	$day_node->setAttribute( 'date', $dayfmt );
	$sth=$dbh->prepare( "select rate_type, inet_ntoa( addr ), proto, port,
					bytes as acct, ports_bytes from cliserv_summary_details 
					where day between ( $day_condition ) and ( $day_condition + interval 1 day - interval 1 second )
				order by bytes desc
			" );
	$sth->execute or die $!;
	my $ar=$sth->fetchall_arrayref( );
	my $internals_day_sibling=Skybill::XML::Element->new( 'internals-rating' );
	my $externals_day_sibling=Skybill::XML::Element->new( 'externals-rating' );
	my $internal_ports_day_sibling=Skybill::XML::Element->new( 'internal-ports-rating' );
	my $external_ports_day_sibling=Skybill::XML::Element->new( 'external-ports-rating' );
	$day_node->addChild( $internals_day_sibling );
	$day_node->addChild( $externals_day_sibling );
	$day_node->addChild( $internal_ports_day_sibling );
	$day_node->addChild( $external_ports_day_sibling );
	foreach(@$ar){
		my( $rate_type, $addr, $proto, $port, $bytes, $port_bytes)= @$_;
		my $rate=Skybill::XML::Element->new( 'rate' );
		$rate->setAttribute( 'ip', $addr );
		$rate->setAttribute( 'bytes', $bytes );
		if($rate_type eq 'clients'){
				$internals_day_sibling->addChild( $rate );
				$rate->setAttribute( 'href', href_chart( $query, { q=>'ds', dst=>$addr, src=>'', my=>$my, d=>$d } ) );
		} else {
				$externals_day_sibling->addChild( $rate );
				$rate->setAttribute( 'href', href_chart( $query, { q=>'ds', src=>$addr, dst=>'', my=>$my, d=>$d } ) );
		}
	}
	@$ar=sort  { $$b[5] <=> $$a[5] } @$ar;
	foreach(@$ar){
		my( $rate_type, $addr, $proto, $port, $bytes, $port_bytes)= @$_;
		my $ports_rate=Skybill::XML::Element->new( 'rate' );
		my ($serv )=getservbyport $port, $proto;
		$ports_rate->setAttribute( 'port', $port.'/'.$proto.($serv?"($serv)":'') );
		$ports_rate->setAttribute( 'bytes', $port_bytes );
		if($rate_type eq 'clients'){
			$internal_ports_day_sibling->addChild( $ports_rate ) if $port_bytes != 0;
		} else {
			$external_ports_day_sibling->addChild( $ports_rate ) if $port_bytes!=0;
		}
	}
	$day_node->setAttribute( 'forming-time', time()-$bill_time );
	return 1;
}

sub get_bill_head{
	my $node=Skybill::XML::Element->new('head');
	my $sth=$dbh->prepare( "select sum(bytes) from daily where 
		day ".$month_condition );
	$sth->execute;
	my( $bytes )=$sth->fetchrow_array;
	$node->setAttribute( 'monthly-bytes', $bytes );
	$sth=$dbh->prepare( "select sum(bytes) from daily where 
		day $year_condition");
	$sth->execute;
	( $bytes )=$sth->fetchrow_array;
	$node->setAttribute( 'yearly-bytes', $bytes );
	$node->setAttribute( 'date', strftime( ( 'ru_RU.UTF-8' eq $locale )?'%A, %d %B %Y':'%A, %B %d, %Y', localtime ) );
	$node->setAttribute( 'contents_amount', CONTENTS_AMOUNT );
	my $seldate;
	my( $year, $month )=split '-', $query->{my} if defined $query->{my};
	my $day=$query->{d} if defined $query->{d};
	$node->setAttribute( 'my', "$year-$month" ) if defined( $month ) and defined( $year );
	$node->setAttribute( 'd', "$year-$day-$month" ) if defined( $month ) and defined( $year ) and defined( $day );
	return $node;
}

sub _get_xslt_sheet{
	my $fn = shift;
  my $stylesheet = $xslt->parse_stylesheet_file( $fn );
	die unless defined $stylesheet;
	return $stylesheet;
}

sub get_xslt_sheet{
	my $fn = shift;
	if( defined $FCGI::Spawn::fcgi ){
		FCGI::Spawn::xinc( $fn, \&_get_xslt_sheet );
	} else {
		_get_xslt_sheet $fn;
	}
}

sub say_bill{
        my( $self, $source ) = @_ ;
				my $xsl_path = $self->{ xsl_path };
        my $stylesheet = get_xslt_sheet( "$xsl_path/bill.xsl" );
        my $results = $stylesheet->transform($source);
        #$stylesheet->output_fh( $results, \*STDOUT ) or die $!;
        # print $stylesheet->output_string( $results ) ;
				$results->setEncoding( 'UTF-8' );
				$results->toFH( \*STDOUT );
}

sub get_query_element{
	my $query=shift;
	my $q_elem=Skybill::XML::Element->new('query');
	foreach( keys %$query ){
		my $option=Skybill::XML::Element->new('option');
		$option->setAttribute( 'name', $_ );
		$option->setAttribute( 'value', $query->{$_} );
		$q_elem->addChild( $option );
	}
	$q_elem->setAttribute( 'action', defined( $ENV{SCRIPT_NAME} ) ? $ENV{SCRIPT_NAME} : '/' );
	$q_elem;
}

sub page_chart{
	my( $parent, $count )=@_;
	$parent->setAttribute( 'count', $count );
	for( 0..( $count-( $count % CONTENTS_AMOUNT ) )/(CONTENTS_AMOUNT) ){
		my $sibling=Skybill::XML::Element->new('page');
		$sibling->setAttribute( 'page', $_ );
		$sibling->setAttribute( 'option-label', $_*CONTENTS_AMOUNT."-".(
				( 		
					( 
						(
							( $_ +1 )*CONTENTS_AMOUNT
						)>$count 
					)?$count:(
						( $_ +1 )*CONTENTS_AMOUNT 
					)
				) 
			) 
		);
		$sibling->setAttribute( 'option', $_ );
		$parent->addChild( $sibling );
	}
}

sub href_chart{
	my( $q, $h )=@_;
	my %href=( %$q, %$h );
	my $qs='?';
	while( my( $name, $value ) = each( %href ) ){
		$qs.="$name=$value&" if( $name ne 'p' and $value ne '' );
	}
	chop $qs;
	( defined( $ENV{SCRIPT_NAME} ) ? $ENV{SCRIPT_NAME} : '/' ).$qs;
}

sub country_code{
	return( ( defined $ENV{COUNTRY_CODE} ) and  ( 'ru' eq lc $ENV{COUNTRY_CODE} ) ) ? 'ru' : 'en';
}

1;
