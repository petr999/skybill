#!/bin/sh

CHROOT_PATH="/jails/internal"
IPACCT_CHROOT_PATH="/jails/external"
BIN_PREFIX="/var/www/ul/skybill/bin"
CHROOT="/usr/sbin/chroot"
CHROOT_CMD="$CHROOT $CHROOT_PATH $BIN_PREFIX"
IPACCT_CHROOT_CMD="$CHROOT $IPACCT_CHROOT_PATH"
IPACCT_MIN_LOG=$CHROOT_PATH/$BIN_PREFIX/../log/ipacct_min.log
date >>$IPACCT_MIN_LOG
min=`date "+%M"`
TIME_MEASURE="/usr/bin/time -h -ao $IPACCT_MIN_LOG "
IPACCTCTL="$IPACCT_CHROOT_CMD /usr/local/sbin/ipacctctl"
BILLED_INTERFACE="rl0"

$CHROOT_CMD/ipacct_dynips.pl
#	$TIME_MEASURE /usr/local/sbin/squid-mysql2ipacct 
$IPACCTCTL ${BILLED_INTERFACE}_ip_acct:${BILLED_INTERFACE} checkpoint 
$IPACCTCTL -ni ${BILLED_INTERFACE}_ip_acct:${BILLED_INTERFACE} show | $CHROOT_CMD/ipacct2mysql.pl
$IPACCTCTL ${BILLED_INTERFACE}_ip_acct:${BILLED_INTERFACE} clear
#$TIME_MEASURE  /bin/cat | $BIN_PREFIX/ipacct2mysql.pl
#/tmp/ipacct/ipacct.10000 
#/bin/cat /tmp/ipacct/ipacct.10001 |/usr/local/sbin/ipacct2mysql raw_out
$TIME_MEASURE $CHROOT_CMD/ipacct_purge.pl
#$TIME_MEASURE  /sbin/ipfw show | $BIN_PREFIX/ipacct_limits
#for min10 in 00 20 40 
for min10 in 00 10 20 30 40 50
#for min10 in 00 15 30 45
do
	[ $min -eq $min10 ] && $CHROOT_CMD/ipacct_10min.sh $min10&
done
