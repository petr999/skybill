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

use Net::Interface;
use Tie::File;
use Socket qw/inet_ntoa/;

use Skybill::Config;

my @addresses = map { inet_ntoa [ $_->address ]->[IF_ADDRESS_NUMBER] } grep { $_->name eq BILLED_INTERFACE; } Net::Interface->interfaces;
my @stored_addresses;
my $addresses_file = realpath( "$skybill_lib/../var" )."/addresses.txt";
tie @stored_addresses, 'Tie::File', $addresses_file or die $!;
foreach my $addr ( @addresses ){
	push( @stored_addresses, $addr ) unless grep { $addr eq $_ } @stored_addresses;
}
