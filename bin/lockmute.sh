#!/bin/bash
PATH=/bin:/usr/bin
gnome-screensaver-command -l
LOCKED=`gnome-screensaver-command -q`
while [ "$LOCKED" == "The screensaver is active" ]; do
  echo "`date` - disable audio"
  amixer -q -D pulse sset Master 0%
  sleep 1
  LOCKED=`gnome-screensaver-command -q`
done
echo "`date` - enable audio"
amixer -q -D pulse sset Master 100%
