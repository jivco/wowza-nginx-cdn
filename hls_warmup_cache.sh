#!/bin/bash

#####################################
# Simple stress tool for HLS stream #
# using curl                        #
#                                   #
# ztodorov@neterra.net              #
#                                   #
# v.0.03                            #
#####################################

URL="http://localhost:8080/dvr/smil:$1.smil"
PLAYLIST="$URL/playlist.m3u8"

while true
  do
    IFS=$'\r\n' GLOBIGNORE='*' command eval  "BITRATE_PLAYLISTS=($(curl -s $PLAYLIST |grep -v '#'))"
    echo ""
    echo "${BITRATE_PLAYLISTS[0]}"
    echo "${BITRATE_PLAYLISTS[1]}"

    
    IFS=$'\r\n' GLOBIGNORE='*' command eval  "CHUNKLIST1=($(curl -s $URL/${BITRATE_PLAYLISTS[0]} |grep -v '#'))"
    IFS=$'\r\n' GLOBIGNORE='*' command eval  "CHUNKLIST2=($(curl -s $URL/${BITRATE_PLAYLISTS[1]} |grep -v '#'))"

    echo "$PLAYLIST"
    echo "${CHUNKLIST1[0]}"
    echo "${CHUNKLIST2[0]}"
    echo "${CHUNKLIST1[-1]}"
    echo "${CHUNKLIST2[-1]}"


    curl -s -o /dev/null "$URL/${CHUNKLIST1[-1]}"
    curl -s -o /dev/null "$URL/${CHUNKLIST2[-1]}"
    sleep 1

    
done

