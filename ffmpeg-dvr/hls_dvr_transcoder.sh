#!/bin/bash
########################
# HLS DVR transcoder   # 
# and nagios check     #
#                      #
# ztodorov@neterra.net #
# ver 1.13             #
########################

# changelog
# ver 1.13 - 05.07.2017 - added transcoding over GPU

# Usage
function usage() {
  echo "DVR mode with two qualities:"
  echo "Usage: ./hls_dvr.sh --mode=dvr --name=bnt1 --dvrwindow=480 --src=udp://239.255.100.1:30000 --vmode=mpeg2 --lqres=640x360 --lqbitrate=764000 --hqres=854x480 --hqbitrate=1596000"
  echo "APPEND_DVR mode with two qualities:"
  echo "Usage: ./hls_dvr.sh --mode=append_dvr --name=bnt1 --src=udp://239.255.100.1:30000 --vmode=mpeg2 --dvrwindow=480 --lqres=640x360 --lqbitrate=764000 --hqres=854x480 --hqbitrate=1596000"
  echo "STATUS mode with two qualities:"
  echo "Usage: ./hls_dvr.sh --mode=status --name=bnt1 --dvrwindow=480"
  echo "The program kills all running processes with the same program name before starting!"
  echo "--mode        >>>>   Can be dvr / append_dvr / status. In append_dvr mode all previous chunks are saved, but you have to manually delete them after removing from playlist! In dvr mode all previous chunks are deleted!"
  echo "--name        >>>>   Name of tv channel"
  echo "--dvrwindow   >>>>   DVR windows in minutes"
  echo "--src       >>>>   Source video url"
  echo "--vmode       >>>>   Input video codec - mpeg2 or h264"
  echo "--lqres       >>>>   Video resolution of the LQ stream. You can see resolution with ffprobe"
  echo "--lqbitrate   >>>>   Total bitrate (audio+video) of the LQ stream"
  echo "--hqres       >>>>   Video resolution of the HQ stream. You can see resolution with ffprobe. Can be set to 'none' (without quotes) if there is no HQ or there is only one quality"
  echo "--hqbitrate   >>>>   Total bitrate (audio+video) of the HQ stream. Can be set to 'none' (without quotes) if there is no HQ or there is only one quality"

  exit 1
}

# Get command line parameters
for i in "$@"
do
  case $i in

    --mode=*)
      MODE="${i#*=}"
      shift # past argument=value
    ;;
    --name=*)
      NAME="${i#*=}"
      shift # past argument=value
    ;;
    --dvrwindow=*)
      DVRWINDOW="${i#*=}"
      shift # past argument=value
    ;;
    --src=*)
      SRC="${i#*=}"
      shift # past argument=value
    ;;
    --lqres=*)
      LQRES="${i#*=}"
      shift # past argument=value
    ;;
    --lqbitrate=*)
      LQBITRATE="${i#*=}"
      shift # past argument=value
    ;;
    --vmode=*)
      VMODE="${i#*=}"
      shift # past argument=value
    ;;
    --hqres=*)
      HQRES="${i#*=}"
      shift # past argument=value
    ;;
    --hqbitrate=*)
      HQBITRATE="${i#*=}"
      shift # past argument=value
    ;;
    --default)
      DEFAULT=YES
      shift # past argument with no value
    ;;
    *)
      # unknown option
    ;;
  esac
done

# Check for all needed command line parameters
if [[ -z "${MODE}" ]]; then
  echo "MODE is not set"
  usage
fi
if [[ -z "${NAME}" ]]; then
  echo "NAME is not set"
  usage
fi
if [[ -z "${SRC}" ]]; then
  echo "SRC is not set"
  usage
fi
if [[ -z "${VMODE}" ]]; then
  echo "VMODE is not set"
  usage
fi
if [[ -z "${HQURL}" ]]; then
  echo "HQURL is not set"
  usage
fi

if [ "${MODE}" != "status" ]; then
  if [[ -z "${DVRWINDOW}" ]]; then
    echo "DVRWINDOW is not set"
    usage
  fi
  if [[ -z "${LQRES}" ]]; then
    echo "LQRES is not set"
    usage
  fi
  if [[ -z "${LQBITRATE}" ]]; then
    echo "LQBITRATE is not set"
    usage
  fi
  if [[ -z "${HQRES}" ]]; then
    echo "HQRES is not set"
    usage
  fi
  if [[ -z "${HQBITRATE}" ]]; then
    echo "HQBITRATE is not set"
    usage
  fi
fi

# screen path
SCREEN='/usr/bin/screen'
hash $SCREEN 2>/dev/null || { echo >&2 "I require SCREEN but it's not installed. yum install scrreen. Aborting."; exit 1; }
# ffmpeg path
FFMPEG='/root/bin/ffmpeg'
hash $FFMPEG 2>/dev/null || { echo >&2 "I require FFMPEG but it's not installed. yum install ffmpeg. Aborting."; exit 1; }

# Chunk duration in miliseconds
CHUNKDURATION=5000
# nginx DVR document root
NGX_ROOT='/mnt/store/nginx_root'
# path to HLS key info file
# key info file can be generated with following commands
# key.txt:
# 7C42F51202FABCA34A38758FA8902A09
#
# xxd -r -p key.txt key.enc
#
#neterra.keyinfo:
#http://clappr.neterra.tv/keys/key?{encKeySessionid}
#/mnt/store/key.enc
KEYINFO='/mnt/store/neterra.keyinfo'
# string to append to screen name to be sure to kill right processes
UNQ_STR='NTR'
# low quality string
LQ='LQ'
# high quality string
HQ='HQ'
# dvr root folder
DVR_ROOT=$NGX_ROOT'/dvr'
# tv program root folder
PROGRAM_ROOT=$DVR_ROOT/$NAME'.smil'

# Generate random string
RANDOM_STR=$UNQ_STR`< /dev/urandom tr -dc A-Z | head -c8`

if [ ! -f "$KEYINFO" ]; then
  echo "KEYINFO file not found! Aborting."
  exit 1
fi

# convert DVR window in chunks
DVRWINDOW=$((DVRWINDOW*60*1000/CHUNKDURATION))

PID=`ps ax|grep 'SCREEN -dmS'|grep $UNQ_STR|grep $NAME|grep -v grep|awk '{print $1}'`

# mode status
if [ "${MODE}" = "status" ]; then

  ERROR=''

  # check pid LQ
  if [[ -z "${PID}" ]]; then
    ERROR="$ERROR $NAME is not running!"
  fi
  #check main playlist for LQ
  if [[ "$(cat $PROGRAM_ROOT/playlist.m3u8|wc -l)" -lt  "4" ]]; then
    ERROR="$ERROR There are not enough rows in $PROGRAM_ROOT/playlist.m3u8!"
  fi
  # check LQ playlist
  if [[ "$(cat $PROGRAM_ROOT/${NAME}_${LQ}.m3u8|wc -l)" -lt  "$DVRWINDOW" ]]; then
    ERROR="$ERROR There are not enough rows in $PROGRAM_ROOT/${NAME}_${LQ}.m3u8!"
  fi
  # check LQ last chunk time
  if test `find $PROGRAM_ROOT -name "$(tail -n 1 $PROGRAM_ROOT/${NAME}_${LQ}.m3u8)" -mmin +1`
  then
    ERROR="$ERROR Last chunk in $PROGRAM_ROOT/${NAME}_${LQ}.m3u8 is too old! Maybe there is no input source."
  fi

  #check main playlist for HQ
  if [[ "$(cat $PROGRAM_ROOT/playlist.m3u8|wc -l)" -lt  "6" ]]; then
    ERROR="$ERROR There are not enough rows in $PROGRAM_ROOT/playlist.m3u8"
  fi
  # check HQ playlist
  if [[ "$(cat $PROGRAM_ROOT/${NAME}_${HQ}.m3u8|wc -l)" -lt  "$DVRWINDOW" ]]; then
    ERROR="$ERROR There are not enough rows in $PROGRAM_ROOT/${NAME}_${HQ}.m3u8!"
  fi
  # check HQ last chunk time
  if test `find $PROGRAM_ROOT -name "$(tail -n 1 $PROGRAM_ROOT/${NAME}_${HQ}.m3u8)" -mmin +1`
  then
    ERROR="$ERROR Last chunk in $PROGRAM_ROOT/${NAME}_${HQ}.m3u8 is too old! Maybe there is no input source."
  fi

  # nagios status
  if [[ -z "${ERROR}" ]]; then
    # everything seems to work
    echo "${NAME} DVR is OK"
    exit 0
  else
    echo "$ERROR"
    exit 2
  fi

  # mode dvr
else
  # create crossdomain file (needed for IE)
  echo '<cross-domain-policy><allow-access-from domain="*" secure="false"/><site-control permitted-cross-domain-policies="all"/></cross-domain-policy>' >$NGX_ROOT'/crossdomain.xml'
  if [ ! -d "$DVR_ROOT" ]; then
    mkdir "$DVR_ROOT"
  fi
  if [ ! -d "$PROGRAM_ROOT" ]; then
    mkdir "$PROGRAM_ROOT"
  fi

  # kill previous
  if [[ -n "${PID}" ]]; then
    kill -9 $PID
  fi

  # skip if mode is append_dvr
  if [ "${MODE}" = "dvr" ]; then
    rm -f $PROGRAM_ROOT/*
  fi
  cd "$PROGRAM_ROOT"

  GOP=$((CHUNKDURATION*25/1000))

  if [ "${VMODE}" = "mpeg2" ]; then
    $SCREEN -dmS $NAME $FFMPEG -hwaccel_device 0 -hwaccel cuvid -c:v mpeg2_cuvid -gpu 0 -deint 2 -i $SRC\?buffer_size=65535&fifo_size=1000000 \
    -map 0:v:0 -map 0:a:0 -vf scale_npp=-1:480 -c:v h264_nvenc -g $GOP -preset slow -b:v $HQBITRATE -maxrate $HQBITRATE -bufsize $HQBITRATE -c:a libfdk_aac -b:a 96k -ac 2 -ar 48000 \
    -f hls -hls_list_size $DVRWINDOW -hls_allow_cache 1 -hls_segment_filename $NAME'_dvr_'$RANDOM_STR'_'$LQ'_'%01d.ts \
    -hls_key_info_file $KEYINFO -hls_flags delete_segments+append_list $NAME'_'$LQ.m3u8 \
    -map 0:v:0 -map 0:a:0 -vf scale_npp=-1:360 -c:v h264_nvenc -g $GOP -preset slow -b:v $LQBITRATE -maxrate $LQBITRATE -bufsize $LQBITRATE -c:a libfdk_aac -b:a 96k -ac 2 -ar 48000 \
    -f hls -hls_list_size $DVRWINDOW -hls_allow_cache 1 -hls_segment_filename $NAME'_dvr_'$RANDOM_STR'_'$HQ'_'%01d.ts \
    -hls_key_info_file $KEYINFO -hls_flags delete_segments+append_list $NAME'_'$HQ.m3u8 \
  fi

  if [ "${VMODE}" = "h264" ]; then
    $SCREEN -dmS $NAME $FFMPEG -hwaccel_device 0 -hwaccel cuvid -c:v h264_cuvid -gpu 0 -deint 2 -i $SRC\?buffer_size=65535&fifo_size=1000000 \
    -map 0:v:0 -map 0:a:0 -vf scale_npp=-1:720 -c:v h264_nvenc -g $GOP -preset slow -b:v $HQBITRATE -maxrate $HQBITRATE -bufsize $HQBITRATE -c:a libfdk_aac -b:a 96k -ac 2 -ar 48000 \
    -f hls -hls_list_size $DVRWINDOW -hls_allow_cache 1 -hls_segment_filename $NAME'_dvr_'$RANDOM_STR'_'$LQ'_'%01d.ts \
    -hls_key_info_file $KEYINFO -hls_flags delete_segments+append_list $NAME'_'$LQ.m3u8 \
    -map 0:v:0 -map 0:a:0 -vf scale_npp=-1:360 -c:v h264_nvenc -g $GOP -preset slow -b:v $LQBITRATE -maxrate $LQBITRATE -bufsize $LQBITRATE -c:a libfdk_aac -b:a 96k -ac 2 -ar 48000 \
    -f hls -hls_list_size $DVRWINDOW -hls_allow_cache 1 -hls_segment_filename $NAME'_dvr_'$RANDOM_STR'_'$HQ'_'%01d.ts \
    -hls_key_info_file $KEYINFO -hls_flags delete_segments+append_list $NAME'_'$HQ.m3u8 \
  fi

  # create temp playlist
  echo '#EXTM3U' > $PROGRAM_ROOT/.playlist.m3u8.tmp
  echo '#EXT-X-VERSION:3' >> $PROGRAM_ROOT/.playlist.m3u8.tmp
  echo "#EXT-X-STREAM-INF:BANDWIDTH=$LQBITRATE,RESOLUTION=$LQRES" >>$PROGRAM_ROOT/.playlist.m3u8.tmp
  echo $NAME'_'$LQ.m3u8 >> $PROGRAM_ROOT/.playlist.m3u8.tmp
  echo "#EXT-X-STREAM-INF:BANDWIDTH=$HQBITRATE,RESOLUTION=$HQRES" >> $PROGRAM_ROOT/.playlist.m3u8.tmp
  echo $NAME'_'$HQ.m3u8 >> $PROGRAM_ROOT/.playlist.m3u8.tmp

  # move temp playlist
  mv $PROGRAM_ROOT/.playlist.m3u8.tmp $PROGRAM_ROOT/playlist.m3u8
fi
