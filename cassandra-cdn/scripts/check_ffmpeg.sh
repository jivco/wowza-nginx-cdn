#!/bin/bash

RESTART=0

tail -n50 /tmp/ffreport.log|egrep '(DTS|expired|Bad|5XX)'

if [ $? -eq 0 ]
then
  RESTART=1
fi

tail -n500 /tmp/ffreport.log|egrep '(\.ts)'

if [ $? -eq 1 ]
then
  RESTART=1
fi

if [ "$RESTART" -eq "1" ]
then
   kill -9 `cat /var/run/ffmpeg.pid`
   /root/ffmpeg-hls-to-udp.sh
   echo "`date` - fmpeg restarted">>/tmp/check_ffmpeg.log
fi
