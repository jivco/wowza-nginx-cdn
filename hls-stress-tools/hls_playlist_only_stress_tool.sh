#!/bin/bash

#####################################
# Simple stress tool for HLS stream #
# using curl                        #
#                                   #
# ztodorov@neterra.net              #
#                                   #
# v.0.03                            #
#####################################

CHUNKDURATION=5
URL="http://94.156.44.142:8080/dvr/$1.smil"
PLAYLIST="$URL/playlist.m3u8?DVR"

#echo "$PLAYLIST"

while true
  do
    IFS=$'\r\n' GLOBIGNORE='*' command eval  "BITRATE_PLAYLISTS=($(curl -s -sH 'Accept-encoding: gzip' --compressed $PLAYLIST |grep -v '#'))"
    #echo ""
    #echo "${BITRATE_PLAYLISTS[0]}"
    #echo "${BITRATE_PLAYLISTS[1]}"

    
    IFS=$'\r\n' GLOBIGNORE='*' command eval  "CHUNKLIST1=($(curl -s -sH 'Accept-encoding: gzip' --compressed $URL/${BITRATE_PLAYLISTS[0]}|grep -v '#'))"
    IFS=$'\r\n' GLOBIGNORE='*' command eval  "CHUNKLIST2=($(curl -s -sH 'Accept-encoding: gzip' --compressed $URL/${BITRATE_PLAYLISTS[1]}|grep -v '#'))"

    #echo "${CHUNKLIST1[0]}"
    #echo "${CHUNKLIST2[0]}"
    #echo "${CHUNKLIST1[-1]}"
    #echo "${CHUNKLIST2[-1]}"
    echo -n "."
    
done

