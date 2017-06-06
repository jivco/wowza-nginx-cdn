#!/bin/bash

((FFREPORT=file=/tmp/ffreport.log ffmpeg -fflags +sortdts+bitexact+genpts+igndts+discardcorrupt -re -i http://172.16.21.1/dvr/bbc_world/1428000/60/playlist.m3u8 -c copy -f mpegts 'udp://127.0.0.1:30000?pkt_size=1316') & echo $! > /var/run/ffmpeg.pid &)
