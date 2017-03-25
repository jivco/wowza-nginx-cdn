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
WOW_TV_URL='http://'$WOW_IP':1935/'$WOW_APP'/'$TV'.smil'
TV_TMP_PATH=$TMP_STORE'/'$WOW_IP.$NGX_APP.$TV'.smil'

function remove_chunks_from_dvr {
  # delete chunks which don't fit in DVR window
  if [ "$TOTAL_CHUNKS" -gt "$MAXCHUNKS" ]; then
    REMOVE_CHUNKS_NUM=$(($TOTAL_CHUNKS-$MAXCHUNKS))
    IFS=$'\r\n' GLOBIGNORE='*' command eval "REMOVE_CHUNKS=$(cat $TV_TMP_PATH.$i'.tmp'|head -n $REMOVE_CHUNKS_NUM)"

    for n in "${REMOVE_CHUNKS[@]}"
    do
      rm -f "$NGX_ROOT/$NGX_APP/$TV.smil/$n"
    done

  fi
}

function gen_chunklist {

  echo '#EXTM3U' >$TV_TMP_PATH.$i'.tmpl'
  echo '#EXT-X-VERSION:3' >>$TV_TMP_PATH.$i'.tmpl'
  echo "#EXT-X-TARGETDURATION:$CHUNKDURATION">>$TV_TMP_PATH.$i'.tmpl'
  echo "#EXT-X-MEDIA-SEQUENCE:$XMS">>$TV_TMP_PATH.$i'.tmpl'
  echo "$AESKEY">>$TV_TMP_PATH.$i'.tmpl'

  # downloading last chunk from Wowza
  WOW_CHUNK=$(curl -s -sH 'Accept-encoding: gzip' --compressed "$WOW_TV_URL/$i"|tail -n 1)
  curl -s $WOW_TV_URL/$WOW_CHUNK -o $NGX_ROOT'/'$NGX_APP'/'$TV'.smil/media_'$CHUNK_PATTERN'_'$LAST_CHUNK_NUM'.ts'
  # writing it to temporary chunklist
  echo 'media_'$CHUNK_PATTERN'_'$LAST_CHUNK_NUM'.ts'>>$TV_TMP_PATH.$i'.tmp'

  cat $TV_TMP_PATH.$i'.tmpl' >$TV_TMP_PATH.$i'.ready'
  echo "'#EXTINF:'$CHUNKDURATION'.0,'">>$TV_TMP_PATH.$i'.ready'
  sed ':a;N;$!ba;s/\n/\n#EXTINF:$CHUNKDURATION.0,\n/g' $TV_TMP_PATH.$i'.tmp' >>$TV_TMP_PATH.$i'.ready'
  mv "$TV_TMP_PATH.$i.ready" "$NGX_ROOT/$NGX_APP/$TV.smil/$i"
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
if [ ! -d "$NGX_ROOT/$NGX_APP/$TV.smil" ]; then
  mkdir "$NGX_ROOT/$NGX_APP/$TV.smil"
fi

# Check if curl is installed
CURL=$(which curl)
if [ -z ${CURL+x} ]; then
  echo "curl is not installed";
  exit;
fi

# Get main playlist from Wowza
# curl 'http://127.0.0.1:1935/dvr/bnt1.smil/playlist.m3u8'
curl -s -sH 'Accept-encoding: gzip' --compressed $WOW_TV_URL/$PLAYLIST -o $TV_TMP_PATH.$PLAYLIST'.tmp'

# get chunklists of different bitrates
IFS=$'\r\n' GLOBIGNORE='*' command eval "BITRATE_CHUNKLISTS=$(cat $TV_TMP_PATH.$PLAYLIST'.tmp'|grep 'chunklist_')"

if [ -z "${BITRATE_CHUNKLISTS[0]}" ]; then
  echo 'No bitrate chunklists found at Wowza server. Exiting.'
  exit
fi

mv "$TV_TMP_PATH.$PLAYLIST.tmp" "$NGX_ROOT/$NGX_APP/$TV.smil/$PLAYLIST"

# checking for previously stored chunks and adding them to chunklists

#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=764000,RESOLUTION=640x360
#chunklist_b764000_slbul.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=1596000,RESOLUTION=854x480
#chunklist_b1596000_slbul.m3u8

#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:5
#EXT-X-MEDIA-SEQUENCE:26383
#EXT-X-KEY:METHOD=AES-128,URI="http://clappr.neterra.tv/keys/key"
#EXTINF:5.0,
#media_b764000_slbul_26383.ts
#EXTINF:5.0,
#media_b764000_slbul_26384.ts
#EXTINF:5.0,
#media_b764000_slbul_26385.ts


# init local chunklists
for i in "${BITRATE_CHUNKLISTS[@]}"
do

  # get chunkduration
  curl -s -sH 'Accept-encoding: gzip' --compressed "$WOW_TV_URL/$i" -o "$TV_TMP_PATH.$i.wow.tmp"
  CHUNKDURATION=$(cat $TV_TMP_PATH.$i'.wow.tmp'|grep 'EXT-X-TARGETDURATION'|awk -F ":" '{print $NF}')
  MAXCHUNKS=$(($DVR_WINDOW*60/$CHUNKDURATION))
  TOTAL_CHUNKS=$(cat $TV_TMP_PATH.$i'.tmp'|wc -l)

  if [ -z ${DISCARD_OLD_DATA+x} ]; then

    # load chunks from directory
    CHUNK_PATTERN=$(echo $i|awk -F "_" '{print $2_$3}')
    cd "$NGX_ROOT/$NGX_APP/$TV.smil"
    ls 'media_'$CHUNK_PATTERN'_*.ts'>$TV_TMP_PATH.$i'.tmp'

    remove_chunks_from_dvr

  else
    rm -f $NGX_ROOT'/'$NGX_APP'/'$TV'.smil/media_'$CHUNK_PATTERN'_*.ts'
    rm -f $TV_TMP_PATH.$i'.tmp'
  fi
done

# Main loop
while true
do
  for i in "${BITRATE_CHUNKLISTS[@]}"
  do

    # get chunkduration and AES key from Wowza
    curl -s -sH 'Accept-encoding: gzip' --compressed $WOW_TV_URL'/'$i -o $TV_TMP_PATH.$i'.wow.tmp'
    CHUNKDURATION=$(cat $TV_TMP_PATH.$i'.wow.tmp'|grep 'EXT-X-TARGETDURATION'|awk -F ":" '{print $NF}')
    AESKEY=$(cat $TV_TMP_PATH.$i'.wow.tmp'|grep 'EXT-X-KEY')
    MAXCHUNKS=$(($DVR_WINDOW*60/$CHUNKDURATION))
    TOTAL_CHUNKS=$(cat $TV_TMP_PATH.$i'.tmp'|wc -l)
    CHUNK_PATTERN=$(echo $i|awk -F "_" '{print $2_$3}')

    if [ -z ${TOTAL_CHUNKS+x} ]; then
      XMS=0
      LAST_CHUNK_NUM=0
    else

      remove_chunks_from_dvr

      XMS=$(head $TV_TMP_PATH.$i'.tmp' -n 1|awk -F "_" '{print $NF}'|awk -F "." '{print $1}')
      LAST_CHUNK_NUM=$(tail -n 1 $i'.tmp' -n 1|awk -F "_" '{print $NF}'|awk -F "." '{print $1}')

    fi

    gen_chunklist

  done

  sleep 1
done
