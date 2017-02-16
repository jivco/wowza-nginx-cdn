<?php
$proxy_deviceid=$_GET['proxy_deviceid'];
$proxy_sessionid=$_GET['proxy_sessionid'];
?>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width">
    <title>Clappr 101</title>
    <script type="text/javascript" src="clappr.min.js"></script>
    <script type="text/javascript" src="level-selector.min.js"></script>
  </head>
  <body>
    <div id="player"></div>
    <script>

      var player = new Clappr.Player({
        source: "http://ott-wowza.neterra.net/cdn/ngrp:1.stream_all/playlist.m3u8?DVR&proxy_deviceid=<?php echo $proxy_deviceid; ?>&proxy_sessionid=<?php echo $proxy_sessionid; ?>",
  	hlsMinimumDvrSize: 0,
  	hlsjsConfig: {
    	  maxMaxBufferLength: 7,
          manifestLoadingTimeOut: 2000,
          manifestLoadingMaxRetry: 3,
          manifestLoadingRetryDelay: 500,
          manifestLoadingMaxRetryTimeout : 64000,
	  debug: true
  	},
        parentId: "#player",
  	autoPlay: true,
        plugins: {'core': [LevelSelector]},
  	levelSelectorConfig: {
      	  labels: {
            2: '720p',
            1: '360p',
            0: '180p',
          },
    	},

        actualLiveTime: true,
        disableVideoTagContextMenu: true,
	useHardwareVideoDecoder: true,
	mediacontrol: {seekbar: "#4D6EAC", buttons: "#66B2FF"},

     });


   </script>
  </body>
</html>

