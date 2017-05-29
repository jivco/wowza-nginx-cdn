ffmpeg -v debug -report -fflags +sortdts+bitexact+genpts+igndts+discardcorrupt -re -i http://172.16.21.1/dvr/bnt1_480p_playlist_all.m3u8 -c copy -f mpegts 'udp://172.16.21.3:33000?pkt_size=1316'
