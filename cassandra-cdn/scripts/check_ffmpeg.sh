#!/bin/bash

RESTART=0

tail -n50 /tmp/ffreport15.log|egrep '(DTS|expired|Bad|5XX|Delay between the first packet and last packet in the muxing queue is|Invalid data)'

if [ $? -eq 0 ]
then
  RESTART=1
fi

tail -n500 /tmp/ffreport15.log|egrep '(\.ts)'

if [ $? -eq 1 ]
then
  RESTART=1
fi

tail -n500 /var/log/nss/nssd.log|grep Timeout|grep "`date --date='1 minutes ago' +"%Y/%m/%d %H:%M"`"|grep "'btv-sd2'"

if [ $? -eq 0 ]
then
  RESTART=1
fi

if [ "$RESTART" -eq "1" ]
then
   kill -9 `cat /var/run/ffmpeg15.pid`
   /root/ffmpeg-hls-to-udp-btv.sh
   echo "`date` - fmpeg-btv restarted">>/tmp/check_ffmpeg.log
fi
