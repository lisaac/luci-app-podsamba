#!/bin/sh

killall smbd 2&> /dev/null
killall nmbd 2&> /dev/null
nmbd -D
smbd --no-process-group &

case $1 in
  daemon) tail -f /var/log/samba/log.nmbd /var/log/samba/log.smbd;;
esac
