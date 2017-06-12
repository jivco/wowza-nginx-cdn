#!/bin/bash

tail -n50 /tmp/ffreport.log|egrep '(DTS|expired|Bad|5XX)'

if [ $? -eq 0 ]
then
   kill -9 `cat /var/run/ffmpeg.pid`
   /root/ffmpeg-hls-to-udp.sh
   echo "`date` - fmpeg restarted">>/tmp/check_ffmpeg.log
fi
