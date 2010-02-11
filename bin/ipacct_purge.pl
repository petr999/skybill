#!/usr/bin/perl -w

use strict;
use warnings;

=pod

=head1 NAME

 ipacct_purge - script to delete expired raw statistics, can be executed frequently ( every minute )

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

purge_raw( DB_RAW_KEEP );

$dbh->disconnect;

sub purge_raw{
	my $keep = shift();
	my $sth=$dbh->prepare( "delete from ".DB_RAW_TABLE." where unix_timestamp( ts ) < unix_timestamp() - ?" );
	$sth->execute( $keep );
#	$sth=$dbh->prepare( "delete from raw_out where unix_timestamp( ts ) < unix_timestamp() - ?" );
#	$sth->execute( $keep );
}
