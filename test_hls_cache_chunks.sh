#!/bin/bash

#####################################
# cache HLS chunks for DVR          #
#                                   #
# ztodorov@neterra.net              #
#                                   #
# v.1.00                            #
#####################################

# Wowza must be in HTTP Origin mode with httpRandomizeMediaName set to false
# cupertino chunk duration must be set to the desired duration
# nginx must provide not too big cache headers for chunk files

# DVR Window in minutes
DVR_WINDOW=240
# TMP path
TMP_STORE='/tmp'
# Nginx document root
NGX_ROOT='/mnt/store/nginx_root'

# help
USAGE_HELP='Usage: hls_cache_chunks.sh bnt1 127.0.0.1 discard_old_data (you can omit "discard_old_data" to load all chunks in the folder before start)'

TV=$1
WOW_IP=$2
DISCARD_OLD_DATA=$3
WOW_APP='dvr'
NGX_APP='dvr'
PLAYLIST='playlist.m3u8'
PLAYLIST_TMP=$PLAYLIST'.tmp'
PLAYLIST_TEMPLATE=$PLAYLIST'.tmpl'
WOW_TV_URL='http://'$WOW_IP':1935/'$WOW_APP'/'$TV'.smil'
TV_PATH_TMP=$TMP_STORE'/'$WOW_IP.$NGX_APP.$TV'.smil'
TV_PATH=$NGX_ROOT'/'$NGX_APP'/'$TV'.smil'

function remove_chunks_from_dvr {
  # delete chunks which don't fit in DVR window
  if [ "$TOTAL_LINES" -gt "$MAX_LINES" ]; then
    REMOVE_CHUNKS_NUM=$(($TOTAL_LINES-$MAX_LINES))
    IFS=$'\r\n' GLOBIGNORE='*' command eval "REMOVE_CHUNKS=($(cat $TV_PATH_TMP.$i.$PLAYLIST_TMP|head -n $REMOVE_CHUNKS_NUM))"

    for n in "${REMOVE_CHUNKS[@]}"
    do
      rm -f "$TV_PATH/$n"
    done

  fi
}

# Main start

# Check for TV name
if [ -z ${1+x} ]; then
  echo "tv name is unset";
  echo $USAGE_HELP;
  exit;
fi

# Check for Wowza ip address
if [ -z ${2+x} ]; then
  echo "wowza ip address is unset";
  echo $USAGE_HELP;
  exit;
fi

# Write crossdomain.xml
echo '<cross-domain-policy><allow-access-from domain="*" secure="false"/><site-control permitted-cross-domain-policies="all"/></cross-domain-policy>' >$NGX_ROOT'/crossdomain.xml'

# Create app dir if not exsists
if [ ! -d "$NGX_ROOT/$NGX_APP" ]; then
  mkdir "$NGX_ROOT/$NGX_APP"
fi

# Create tv dir if not exsists
if [ ! -d "$TV_PATH" ]; then
  mkdir "$TV_PATH"
fi

# Check if curl is installed
CURL=$(which curl)
if [ -z ${CURL+x} ]; then
  echo "curl is not installed";
  exit;
fi

# Get main playlist from Wowza
# curl 'http://127.0.0.1:1935/dvr/bnt1.smil/playlist.m3u8'
curl -s -sH 'Accept-encoding: gzip' --compressed $WOW_TV_URL/$PLAYLIST -o $TV_PATH_TMP.$PLAYLIST_TMP

# get chunklists of different bitrates
IFS=$'\r\n' GLOBIGNORE='*' command eval "BITRATE_CHUNKLISTS=($(cat $TV_PATH_TMP.$PLAYLIST_TMP|grep 'chunklist_'))"

if [ -z "${BITRATE_CHUNKLISTS[0]}" ]; then
  echo 'No bitrate chunklists found at Wowza server. Exiting.'
  exit
fi

mv "$TV_PATH_TMP.$PLAYLIST_TMP" "$TV_PATH/$PLAYLIST"

# checking for previously stored chunks and adding them to chunklists

#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=764000,RESOLUTION=640x360
#chunklist_b764000_slbul.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=1596000,RESOLUTION=854x480
#chunklist_b1596000_slbul.m3u8



# init local chunklists
for i in "${BITRATE_CHUNKLISTS[@]}"
do

  # get chunkduration from Wowza chunklist

  #EXTM3U
  #EXT-X-VERSION:3
  #EXT-X-TARGETDURATION:5
  #EXT-X-MEDIA-SEQUENCE:26383
  #EXT-X-KEY:METHOD=AES-128,URI='http://clappr.neterra.tv/keys/key'
  #EXTINF:5.0,
  #media-u6i32508m_b764000_slbul_32908.ts

  curl -s -sH 'Accept-encoding: gzip' --compressed "$WOW_TV_URL/$i" -o "$TV_PATH_TMP.$i.$PLAYLIST"
  CHUNKDURATION=$(cat $TV_PATH_TMP.$i.$PLAYLIST|grep 'EXT-X-TARGETDURATION'|awk -F ":" '{print $NF}')
  MAX_LINES=$((2*$DVR_WINDOW*60/$CHUNKDURATION))

  if [ -z ${DISCARD_OLD_DATA+x} ]; then

    # load chunks from directory
    CHUNK_PATTERN=$(echo $i|awk -F "." '{print $1}'|awk -F "_" '{print $(NF-1)"_"$NF}')
    cd "$TV_PATH"
    ls '*'$CHUNK_PATTERN'*.ts'>$TV_PATH_TMP.$i.$PLAYLIST_TMP
    echo "'#EXTINF:'$CHUNKDURATION'.0,'">$TV_PATH_TMP.$i'.dashed'
    sed ':a;N;$!ba;s/\n/\n#EXTINF:$CHUNKDURATION.0,\n/g' $TV_PATH_TMP.$i.$PLAYLIST_TMP >>$TV_PATH_TMP.$i'.dashed'
    mv $TV_PATH_TMP.$i'.dashed' $TV_PATH_TMP.$i.$PLAYLIST_TMP
    TOTAL_LINES=$(cat $TV_PATH_TMP.$i.$PLAYLIST_TMP|wc -l)

    remove_chunks_from_dvr

  else
    rm -f $TV_PATH'/*'$CHUNK_PATTERN'*.ts'
    rm -f $TV_PATH_TMP.$i.$PLAYLIST_TMP
  fi
done

# Main loop
while true
do
  for i in "${BITRATE_CHUNKLISTS[@]}"
  do

    # get chunkduration and AES key from Wowza
    curl -s -sH 'Accept-encoding: gzip' --compressed "$WOW_TV_URL/$i" -o "$TV_PATH_TMP.$i.$PLAYLIST"
    CHUNKDURATION=$(cat $TV_PATH_TMP.$i.$PLAYLIST|grep 'EXT-X-TARGETDURATION'|awk -F ":" '{print $NF}')
    AESKEY=$(cat $TV_PATH_TMP.$i.$PLAYLIST|grep 'EXT-X-KEY')
    # because of metadata
    MAX_LINES=$((2*$DVR_WINDOW*60/$CHUNKDURATION))
    TOTAL_LINES=$(cat $TV_PATH_TMP.$i.$PLAYLIST_TMP|wc -l)
    CHUNK_PATTERN=$(echo $i|awk -F "." '{print $1}'|awk -F "_" '{print $(NF-1)"_"$NF}')

    if [ -z ${TOTAL_LINES+x} ]; then
      XMS=0
      LAST_CHUNK_NUM="0"
    else

      remove_chunks_from_dvr

      XMS=$(head $TV_PATH_TMP.$i.$PLAYLIST_TMP -n 2|grep -v '#'|awk -F "_" '{print $NF}'|awk -F "." '{print $1}')
      LAST_CHUNK_NUM=$(tail -n 1 $TV_PATH_TMP.$i.$PLAYLIST_TMP|awk -F "_" '{print $NF}'|awk -F "." '{print $1}')
      LAST_CHUNK_NUM=$((LAST_CHUNK_NUM++))

    fi

    echo '#EXTM3U' >$TV_PATH_TMP.$i.$PLAYLIST_TEMPLATE
    echo '#EXT-X-VERSION:3' >>$TV_PATH_TMP.$i.$PLAYLIST_TEMPLATE
    echo "#EXT-X-TARGETDURATION:$CHUNKDURATION">>$TV_PATH_TMP.$i.$PLAYLIST_TEMPLATE
    echo "#EXT-X-MEDIA-SEQUENCE:$XMS">>$TV_PATH_TMP.$i.$PLAYLIST_TEMPLATE
    echo "$AESKEY">>$TV_PATH_TMP.$i.$PLAYLIST_TEMPLATE

    # downloading last chunk from Wowza
    WOW_CHUNK=$(curl -s -sH 'Accept-encoding: gzip' --compressed "$WOW_TV_URL/$i"|tail -n 1)

    if [ "$WOW_CHUNK" != "$WOW_CHUNK_LAST" ]; then

      curl -s $WOW_TV_URL/$WOW_CHUNK -o $TV_PATH'/media_'$CHUNK_PATTERN'_'$LAST_CHUNK_NUM'.ts'
      # writing it to temporary chunklist
      echo "#EXTINF:$CHUNKDURATION.0,">>$TV_PATH_TMP.$i.$PLAYLIST_TMP
      echo 'media_'$CHUNK_PATTERN'_'$LAST_CHUNK_NUM'.ts'>>$TV_PATH_TMP.$i.$PLAYLIST_TMP

      cat $TV_PATH_TMP.$i.$PLAYLIST_TEMPLATE >$TV_PATH_TMP.$i'.ready'
      cat $TV_PATH_TMP.$i.$PLAYLIST_TMP >>$TV_PATH_TMP.$i'.ready'

      mv "$TV_PATH_TMP.$i.ready" "$TV_PATH/$i"

      WOW_CHUNK_LAST=$WOW_CHUNK
    fi

  done

  sleep 1
done
