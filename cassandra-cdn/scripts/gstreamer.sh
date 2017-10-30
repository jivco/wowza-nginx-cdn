#!/bin/bash
gst-launch-1.0 -v souphttpsrc location=http://example.net/playlist.m3u8 ! hlsdemux ! tsdemux ! mpegtsmux ! udpsink port=5000 host=127.0.0.1
