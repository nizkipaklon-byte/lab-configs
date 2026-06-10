#!/bin/bash
DATE=$(date +%Y%m%d)
HOST=$(hostname)
TMPDIR=/tmp/backup_${HOST}_${DATE}
ARCHIVE=/tmp/backup_${HOST}_${DATE}.tar.gz
MOUNT=/mnt/backups
LOG=/var/log/backup.log
echo "[$(date)] Starting backup" >> $LOG
mkdir -p $TMPDIR/$HOST
mkdir -p $MOUNT
cp /etc/nftables/*.nft $TMPDIR/$HOST/ 2>/dev/null
cp /etc/sysconfig/network-scripts/ifcfg-* $TMPDIR/$HOST/ 2>/dev/null
cp /etc/NetworkManager/system-connections/* $TMPDIR/$HOST/ 2>/dev/null
ip a > $TMPDIR/$HOST/ip_a.txt
ip r > $TMPDIR/$HOST/ip_r.txt
nft list ruleset > $TMPDIR/$HOST/nftables.txt
tar -czf $ARCHIVE -C /tmp backup_${HOST}_${DATE}
mount -t cifs //192.168.16.254/Backups $MOUNT -o credentials=/root/.smbcredentials,uid=0,gid=0
mkdir -p $MOUNT/$HOST
cp $ARCHIVE $MOUNT/$HOST/
umount $MOUNT
rm -rf $TMPDIR $ARCHIVE
echo "[$(date)] Backup done" >> $LOG
