#!/bin/sh

kill -9 $(pidof smbd) 2&> /dev/null
kill -9 $(pidof nmbd) 2&> /dev/null
nmbd -D
smbd --no-process-group &

case $1 in
  daemon) tail -f /var/log/samba/log.nmbd /var/log/samba/log.smbd;;
esac
