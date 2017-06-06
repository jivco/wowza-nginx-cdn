#!/bin/bash

tail -n50 /tmp/ffreport.log|grep "Non-monotonous DTS in output stream"

if [ $? -eq 0 ]
then
 kill -9 `cat /var/run/ffmpeg.pid`
 /root/ffmpeg-hls-to-udp.sh
fi
