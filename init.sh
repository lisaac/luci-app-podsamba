#!/bin/sh

killall smbd 2&> /dev/null
killall nmbd 2&> /dev/null
smbd && nmbd

case $1 in
  daemon) tail -f /dev/stdout
esac