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
URL="http://172.16.21.1/dvr"
PLAYLIST="$URL/bnt1_480p_playlist_all.m3u8"

while true
  do
    
    IFS=$'\r\n' GLOBIGNORE='*' command eval  "CHUNKLIST1=($(curl -s -sH 'Accept-encoding: gzip' --compressed ${PLAYLIST} |grep -v '#'))"

    echo "${CHUNKLIST1[0]}"
    echo "${CHUNKLIST1[-1]}"

    FIRSTCH1=0
    LASTCH1=${#CHUNKLIST1[@]}

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
          CHUNKS1="$CHUNKS1 $URL/${CHUNKLIST1[$CHUNK1]}"
        done


        #echo $CHUNKS1
        curl -s $CHUNKS1 >/dev/null 2>&1
        echo -n "."

    done

    
done
