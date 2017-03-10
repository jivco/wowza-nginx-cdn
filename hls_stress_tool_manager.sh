#!/bin/bash

START=1
END=$2
 
for (( c=$START; c<=$END; c++ ))
do
	./hls_stress_tool.sh $1 >/dev/null 2>&1 &
done

read -n1 -r -p "Press space to continue..." key

if [ "$key" = '' ]; then
      killall hls_stress_tool.sh
fi
