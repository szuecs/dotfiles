#!/bin/bash

PATH="/bin:/usr/bin"
TIME_TRACKER_DIR="$HOME/go/src/github.com/szuecs/time-tracker"

function signin() {
  {
    echo "";
    date | xargs echo -n "$1"
    echo -n ";"
  } >> "$TIME_TRACKER_DIR/tt_$(date +%Y-%m-%d).csv"
}

function signoff () {
  {
    date | xargs echo -n "$1"
  } >> "$TIME_TRACKER_DIR/tt_$(date +%Y-%m-%d).csv"
}


gnome-screensaver-command -l

signoff

LOCKED=$(gnome-screensaver-command -q)
while [ "$LOCKED" == "The screensaver is active" ]; do
  echo "$(date) - disable audio"
  amixer -q -D pulse sset Master 0%
  sleep 1
  LOCKED=$(gnome-screensaver-command -q)
done
echo "$(date) - enable audio"
amixer -q -D pulse sset Master 50%

signin
