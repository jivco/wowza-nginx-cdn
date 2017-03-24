#!/bin/bash

#####################################
# cache and register chunks         #
#                                   #
# ztodorov@neterra.net              #
#                                   #
# v.0.03                            #
#####################################

WOW_APP='dvr'
NGX_APP='dvr'
SMIL='smil'
NGX_CHNL_DIR_NAME=$1.$SMIL
WOW_URL="http://$2:1935/$WOW_APP/$NGX_CHNL_DIR_NAME"
WOW_PLAYLIST=$WOW_URL'/playlist.m3u8'
BITRATE1='360p'
RESOLUTION1='640x360'
BANDWIDTH1='764000'
BITRATE2='480p'
RESOLUTION2='854x480'
BANDWIDTH2='1596000'
TMP_STORE='/tmp'
NGX_ROOT='/mnt/store/nginx_root'
NGX_BITRATE_URL1=$1'_'$BITRATE1'.m3u8'
NGX_BITRATE_URL2=$1'_'$BITRATE2'.m3u8'
NGX_BITRATE1=$NGX_ROOT'/'$NGX_APP'/'$NGX_CHNL_DIR_NAME'/'$NGX_BITRATE_URL1
NGX_BITRATE2=$NGX_ROOT'/'$NGX_APP'/'$NGX_CHNL_DIR_NAME'/'$NGX_BITRATE_URL2
NGX_PLAYLIST1=$TMP_STORE'/'$NGX_APP.$2.$1.$BITRATE1'.tmpl'
NGX_PLAYLIST2=$TMP_STORE'/'$NGX_APP.$2.$1.$BITRATE2'.tmpl'
NGX_BITRATE1_TMP=$TMP_STORE'/'$NGX_APP.$2.$1.$BITRATE1'.tmp'
NGX_BITRATE2_TMP=$TMP_STORE'/'$NGX_APP.$2.$1.$BITRATE2'.tmp'
NGX_MAIN_PLAYLIST_TMP=$TMP_STORE'/'$NGX_APP.$2.$1.playlist'.tmp'
NGX_MAIN_PLAYLIST=$NGX_ROOT'/'$NGX_APP'/'$NGX_CHNL_DIR_NAME'/playlist.m3u8'
# in seconds
CHUNKDURATION=5
# in hours
DVR_WINDOW=4
MAXCHUNKS=$(($DVR_WINDOW*3600/$CHUNKDURATION))
MAXLINES=$((2*$MAXCHUNKS))
USAGE_HELP='Usage: hls_cache_chunks.sh bnt1 127.0.0.1'

function gen_chunklist {
    if [ "$(cat $NGX_PLAYLIST|wc -l)" -eq "0" ]; then
       touch $NGX_PLAYLIST;
    fi

    if [ "$(cat $NGX_PLAYLIST|wc -l)" -ge "$MAXLINES" ]; then
       # Remove first 2 rows of playlist - this is how playlist rotation is made
       NGX_CHUNK_RM=$(tail -n 1 $NGX_PLAYLIST)
       tail -n +3 $NGX_PLAYLIST>$NGX_PLAYLIST.tmp;
       mv $NGX_PLAYLIST.tmp $NGX_PLAYLIST
       rm "$NGX_ROOT/$NGX_APP/$NGX_CHNL_DIR_NAME/$NGX_CHUNK_RM"
    fi
    
    NGX_CHUNK=($(tail -n 1 $NGX_PLAYLIST)) 
    XMS_LAST=$(tail -n 1 $NGX_PLAYLIST|awk -F "_" '{print $NF}'|awk -F "." '{print $1}')
    XMS=$(head $NGX_PLAYLIST -n2|grep -v "#"|awk -F "_" '{print $NF}'|awk -F "." '{print $1}')

    if [ -n "$XMS_LAST" ]; then
      if [ -n "$XMS" ]; then
        if [[ "$XMS_LAST" -lt "$XMS" ]]; then
          echo -n ''>$NGX_PLAYLIST
        fi
      fi
    fi

    if [ -n "${WOW_CHUNKLIST[-1]}" ]; then
      XMS_WOW=$(echo ${WOW_CHUNKLIST[-1]}|awk -F "_" '{print $NF}'|awk -F "." '{print $1}')
      if [[ "$XMS_WOW" != "$XMS_LAST" ]]; then
        curl -s -o $NGX_ROOT/$NGX_APP/$NGX_CHNL_DIR_NAME/${WOW_CHUNKLIST[-1]} $WOW_URL/${WOW_CHUNKLIST[-1]} >/dev/null 2>&1
        echo "#EXTINF:5.0," >>$NGX_PLAYLIST;
        echo ${WOW_CHUNKLIST[-1]} >>$NGX_PLAYLIST;
      fi
    fi


    echo '#EXTM3U' >$NGX_BITRATE_TMP
    echo '#EXT-X-VERSION:3' >>$NGX_BITRATE_TMP
    echo "#EXT-X-TARGETDURATION:$CHUNKDURATION">>$NGX_BITRATE_TMP
    echo "#EXT-X-MEDIA-SEQUENCE:$XMS">>$NGX_BITRATE_TMP
    echo '#EXT-X-KEY:METHOD=AES-128,URI="http://clappr.neterra.tv/keys/key?{encKeySessionid}"'>>$NGX_BITRATE_TMP

    cat $NGX_PLAYLIST >>$NGX_BITRATE_TMP
    mv $NGX_BITRATE_TMP $NGX_BITRATE
}

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

echo '<cross-domain-policy><allow-access-from domain="*" secure="false"/><site-control permitted-cross-domain-policies="all"/></cross-domain-policy>' >$NGX_ROOT'/crossdomain.xml'

rm $NGX_PLAYLIST1 $NGX_PLAYLIST2 $NGX_BITRATE1_TMP  $NGX_BITRATE2_TMP

if [ ! -d "$NGX_ROOT/$NGX_APP" ]; then
  mkdir "$NGX_ROOT/$NGX_APP"
fi

if [ ! -d "$NGX_ROOT/$NGX_APP/$NGX_CHNL_DIR_NAME" ]; then
  mkdir "$NGX_ROOT/$NGX_APP/$NGX_CHNL_DIR_NAME"
fi

echo '#EXTM3U'>$NGX_MAIN_PLAYLIST_TMP
echo '#EXT-X-VERSION:3'>>$NGX_MAIN_PLAYLIST_TMP
echo "#EXT-X-STREAM-INF:BANDWIDTH=$BANDWIDTH1,RESOLUTION=$RESOLUTION1">>$NGX_MAIN_PLAYLIST_TMP
echo "$NGX_BITRATE_URL1">>$NGX_MAIN_PLAYLIST_TMP
echo "#EXT-X-STREAM-INF:BANDWIDTH=$BANDWIDTH2,RESOLUTION=$RESOLUTION2">>$NGX_MAIN_PLAYLIST_TMP
echo "$NGX_BITRATE_URL2">>$NGX_MAIN_PLAYLIST_TMP

mv $NGX_MAIN_PLAYLIST_TMP $NGX_MAIN_PLAYLIST

IFS=$'\r\n' GLOBIGNORE='*' command eval "BITRATE_WOW_PLAYLISTS=($(curl -s -sH 'Accept-encoding: gzip' --compressed $WOW_PLAYLIST |grep -v '#'))"

while true
  do
    IFS=$'\r\n' GLOBIGNORE='*' command eval "WOW_CHUNKLIST1=($(curl -s -sH 'Accept-encoding: gzip' --compressed $WOW_URL/${BITRATE_WOW_PLAYLISTS[0]} |grep -v '#'))"
    IFS=$'\r\n' GLOBIGNORE='*' command eval "WOW_CHUNKLIST2=($(curl -s -sH 'Accept-encoding: gzip' --compressed $WOW_URL/${BITRATE_WOW_PLAYLISTS[1]} |grep -v '#'))"
    NGX_PLAYLIST=$NGX_PLAYLIST1
    NGX_CHUNK=$NGX_CHUNK1
    WOW_CHUNKLIST=("${WOW_CHUNKLIST1[@]}")
    NGX_BITRATE_TMP=$NGX_BITRATE1_TMP
    NGX_BITRATE=$NGX_BITRATE1
    gen_chunklist

    NGX_PLAYLIST=$NGX_PLAYLIST2
    NGX_CHUNK=$NGX_CHUNK2
    WOW_CHUNKLIST=("${WOW_CHUNKLIST2[@]}")
    NGX_BITRATE_TMP=$NGX_BITRATE2_TMP
    NGX_BITRATE=$NGX_BITRATE2
    gen_chunklist
    
    sleep 1
    
done
