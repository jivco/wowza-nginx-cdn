#!/bin/bash

#####################################
# cache and register chunks         #
#                                   #
# ztodorov@neterra.net              #
#                                   #
# v.0.03                            #
#####################################

USAGE_HELP='Usage: hls_cache_chunks.sh bnt1 127.0.0.1'

if [ -z ${1+x} ]; then 
  echo "channel name is unset";
  echo $USAGE_HELP;
  exit;
fi

if [ -z ${2+x} ]; then 
  echo "wowza ip is unset";
  echo $USAGE_HELP;
  exit;
fi

WOW_URL="http://$2:1935/dvr/$1.smil"
WOW_PLAYLIST="$WOW_URL/playlist.m3u8"
BITRATE1='360p'
BITRATE2='480p'
TMP_STORE='/tmp/tmp'
NGX_ROOT='/tmp/tmp'
NGX_BITRATE1=$NGX_ROOT/$1_$BITRATE1.m3u8
NGX_BITRATE2=$NGX_ROOT/$1_$BITRATE2.m3u8
NGX_PLAYLIST1=$TMP_STORE/$2.$1.$BITRATE1.tmpl
NGX_PLAYLIST2=$TMP_STORE/$2.$1.$BITRATE2.tmpl
NGX_BITRATE1_TMP=$TMP_STORE/$2.$1.$BITRATE1.tmp
NGX_BITRATE2_TMP=$TMP_STORE/$2.$1.$BITRATE2.tmp
# in seconds
CHUNKDURATION=5
# in hours
DVR_WINDOW=8
MAXCHUNKS=$(($DVR_WINDOW*3600/$CHUNKDURATION))
MAXLINES=$((2*$MAXCHUNKS))

rm $NGX_PLAYLIST1 $NGX_PLAYLIST2 $NGX_BITRATE1_TMP  $NGX_BITRATE2_TMP

function gen_playlist {
    if [ "$(cat $NGX_PLAYLIST|wc -l)" -eq "0" ]; then
       touch $NGX_PLAYLIST;
    fi

    if [ "$(cat $NGX_PLAYLIST|wc -l)" -eq "$MAXLINES" ]; then
       # Remove first 2 rows of playlist - this is how playlist rotation is made
       tail -n +2 $NGX_PLAYLIST>$NGX_PLAYLIST;
    fi
    
    NGX_CHUNK=($(tail -n 1 $NGX_PLAYLIST)) 

    if [ "${WOW_CHUNKLIST[-1]}" != "$NGX_CHUNK" ]; then
      curl -s -o /dev/null $WOW_URL/${WOW_CHUNKLIST[-1]} >/dev/null 2>&1
      echo "#EXTINF:5.0," >>$NGX_PLAYLIST;
      echo ${WOW_CHUNKLIST[-1]} >>$NGX_PLAYLIST;
    fi

    XMS=$(head $NGX_PLAYLIST -n2|grep -v "#"|awk -F "_" '{print $5}'|awk -F "." '{print $1}')

    echo '#EXTM3U' >$NGX_BITRATE_TMP
    echo '#EXT-X-VERSION:3' >>$NGX_BITRATE_TMP
    echo "#EXT-X-TARGETDURATION:$CHUNKDURATION">>$NGX_BITRATE_TMP
    echo "#EXT-X-MEDIA-SEQUENCE:$XMS">>$NGX_BITRATE_TMP
    echo '#EXT-X-KEY:METHOD=AES-128,URI="http://clappr.neterra.tv/keys/key?{encKeySessionid}"'>>$NGX_BITRATE_TMP

    cat $NGX_PLAYLIST >>$NGX_BITRATE_TMP
    mv $NGX_BITRATE_TMP $NGX_BITRATE
}

while true
  do
    IFS=$'\r\n' GLOBIGNORE='*' command eval  "BITRATE_WOW_PLAYLISTS=($(curl -s -sH 'Accept-encoding: gzip' --compressed $WOW_PLAYLIST |grep -v '#'))"
    IFS=$'\r\n' GLOBIGNORE='*' command eval "WOW_CHUNKLIST1=($(curl -s -sH 'Accept-encoding: gzip' --compressed $WOW_URL/${BITRATE_WOW_PLAYLISTS[0]} |grep -v '#'))"
    IFS=$'\r\n' GLOBIGNORE='*' command eval "WOW_CHUNKLIST2=($(curl -s -sH 'Accept-encoding: gzip' --compressed $WOW_URL/${BITRATE_WOW_PLAYLISTS[1]} |grep -v '#'))"

    NGX_PLAYLIST=$NGX_PLAYLIST1
    NGX_CHUNK=$NGX_CHUNK1
    WOW_CHUNKLIST=("${WOW_CHUNKLIST1[@]}")
    NGX_BITRATE_TMP=$NGX_BITRATE1_TMP
    NGX_BITRATE=$NGX_BITRATE1
    gen_playlist

    NGX_PLAYLIST=$NGX_PLAYLIST2
    NGX_CHUNK=$NGX_CHUNK2
    WOW_CHUNKLIST=("${WOW_CHUNKLIST2[@]}")
    NGX_BITRATE_TMP=$NGX_BITRATE2_TMP
    NGX_BITRATE=$NGX_BITRATE2
    gen_playlist
    
    sleep 1
    
done

