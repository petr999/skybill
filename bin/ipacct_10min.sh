#!/bin/sh

BIN_PREFIX="/var/www/ul/skybill/bin"
CHROOT_PATH="/jails/internal"
#IPACCT_10MIN_LOG=$CHROOT_PATH/$BIN_PREFIX/../log/ipacct_10min.log
IPACCT_10MIN_LOG=$BIN_PREFIX/../log/ipacct_10min.log
CHROOT="/usr/sbin/chroot"
#CHROOT_CMD="$CHROOT $CHROOT_PATH $BIN_PREFIX"
CHROOT_CMD=$BIN_PREFIX
date >>$IPACCT_10MIN_LOG
TIME_MEASURE="/usr/bin/time -h -ao $IPACCT_10MIN_LOG "
$TIME_MEASURE $CHROOT_CMD/ipacct_cliserv.pl
for min20 in 00 20 40 
do
	[ $1 -eq $min20 ] && $TIME_MEASURE $CHROOT_CMD/ipacct_details.pl
done
$TIME_MEASURE $CHROOT_CMD/ipacct_cliserv_summary.pl
