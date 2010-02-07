#!/bin/sh

BIN_PREFIX=/usr/local/jail/internal/var/www/skybill/bin
IPACCT_10MIN_LOG=$BIN_PREFIX/../log/ipacct_10min.log
date >>$IPACCT_10MIN_LOG
TIME_MEASURE="/usr/bin/time -h -ao $IPACCT_10MIN_LOG "
$TIME_MEASURE $BIN_PREFIX/ipacct_cliserv.pl
for min20 in 00 20 40 
do
	[ $1 -eq $min20 ] && $TIME_MEASURE $BIN_PREFIX/ipacct_details.pl
done
$TIME_MEASURE $BIN_PREFIX/ipacct_cliserv_summary.pl
