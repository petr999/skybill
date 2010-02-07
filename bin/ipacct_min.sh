#!/bin/sh

CHROOT_PATH= #/usr/local/jail/internal
BIN_PREFIX=/usr/local/jail/internal/var/www/skybill/bin
CHROOT_CMD=$BIN_PREFIX #/usr/sbin/chroot -u 32765 -g 32765 $CHROOT_PATH $BIN_PREFIX
IPACCT_MIN_LOG=$BIN_PREFIX/../log/ipacct_min.log
date >>$IPACCT_MIN_LOG
min=`date "+%M"`
TIME_MEASURE="/usr/bin/time -h -ao $IPACCT_MIN_LOG "
#	$TIME_MEASURE /usr/local/sbin/squid-mysql2ipacct 
$TIME_MEASURE  /bin/cat | $BIN_PREFIX/ipacct2mysql.pl
#/tmp/ipacct/ipacct.10000 
#/bin/cat /tmp/ipacct/ipacct.10001 |/usr/local/sbin/ipacct2mysql raw_out
$TIME_MEASURE $BIN_PREFIX/ipacct_purge.pl
#$TIME_MEASURE  /sbin/ipfw show | $BIN_PREFIX/ipacct_limits
$BIN_PREFIX/ipacct_dynips.pl
#for min10 in 00 20 40 
for min10 in 00 10 20 30 40 50
#for min10 in 00 15 30 45
do
	[ $min -eq $min10 ] && $BIN_PREFIX/ipacct_10min.sh $min10&
done
