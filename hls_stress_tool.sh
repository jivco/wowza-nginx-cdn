#!/bin/bash

#####################################
# Simple stress tool for HLS stream #
# using curl                        #
#                                   #
# ztodorov@neterra.net              #
#                                   #
# v.0.04                            #
#####################################

CHUNKDURATION=5
URL="http://94.156.44.142:8080/dvr/$1.smil"
PLAYLIST="$URL/playlist.m3u8?DVR"

while true
  do
    IFS=$'\r\n' GLOBIGNORE='*' command eval  "BITRATE_PLAYLISTS=($(curl -s -sH 'Accept-encoding: gzip' --compressed $PLAYLIST |grep -v '#'))"
    echo ""
    echo "${BITRATE_PLAYLISTS[0]}"
    echo "${BITRATE_PLAYLISTS[1]}"

    
    IFS=$'\r\n' GLOBIGNORE='*' command eval  "CHUNKLIST1=($(curl -s -sH 'Accept-encoding: gzip' --compressed $URL/${BITRATE_PLAYLISTS[0]} |grep -v '#'))"
    IFS=$'\r\n' GLOBIGNORE='*' command eval  "CHUNKLIST2=($(curl -s -sH 'Accept-encoding: gzip' --compressed $URL/${BITRATE_PLAYLISTS[1]} |grep -v '#'))"

    echo "$PLAYLIST"
    echo "${CHUNKLIST1[0]}"
    echo "${CHUNKLIST2[0]}"
    echo "${CHUNKLIST1[-1]}"
    echo "${CHUNKLIST2[-1]}"

    FIRSTCH1=0
    FIRSTCH2=0
    LASTCH1=${#CHUNKLIST1[@]}
    LASTCH2=${#CHUNKLIST2[@]}

    #echo $FIRSTCH1
    #echo $FIRSTCH2
    #echo $LASTCH1
    #echo $LASTCH2

    end=$((SECONDS+$CHUNKDURATION))

    while [ $SECONDS -lt $end ]
      do

        CHUNKS1=''
        CHUNKS2=''

        for i in {1..10}
        do
          CHUNK1=`shuf -i $FIRSTCH1-$LASTCH1 -n 1 -z`
          CHUNK2=`shuf -i $FIRSTCH2-$LASTCH2 -n 1 -z`
          CHUNKS1="$CHUNKS1 $URL/${CHUNKLIST1[$CHUNK1]}"
          CHUNKS2="$CHUNKS2 $URL/${CHUNKLIST2[$CHUNK2]}"
        done


        #echo $CHUNKS1
        curl -s $CHUNKS1 >/dev/null 2>&1
        echo -n "."
        #echo $CHUNKS2
        curl -s $CHUNKS2 >/dev/null 2>&1
        echo -n "#"

    done

    
done

