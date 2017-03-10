#!/bin/bash

#####################################
# Simple stress tool for HLS stream #
# using curl                        #
#                                   #
# ztodorov@neterra.net              #
#                                   #
# v.0.01                            #
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

    FIRSTCH1=0
    FIRSTCH2=0
    LASTCH1=${#CHUNKLIST1[@]}
    LASTCH2=${#CHUNKLIST2[@]}

    for (( c=$FIRSTCH1; c<=$LASTCH1; c++ ))
    do
      CHUNKS1="$CHUNKS1 $URL/${CHUNKLIST1[$c]}"
    done

    for (( c=$FIRSTCH2; c<=$LASTCH2; c++ ))
    do
      CHUNKS2="$CHUNKS2 $URL/${CHUNKLIST2[$c]}"
    done

    curl -s $CHUNKS1 >/dev/null 2>&1
    curl -s $CHUNKS2 >/dev/null 2>&1
    
done

