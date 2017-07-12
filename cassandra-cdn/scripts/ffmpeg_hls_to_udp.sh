#!/bin/bash

((FFREPORT=file=/tmp/ffreport15.log /root/bin/ffmpeg -re -i http://172.16.21.1/dvr/btv/1428000/60/chunklist.m3u8 -c copy -f mpegts 'udp://127.0.0.1:30015?pkt_size=188&buffer_size=65535' >/dev/null 2>/dev/null) & echo $! > /var/run/ffmpeg15.pid &)

