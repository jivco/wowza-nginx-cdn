<?php

$cluster   = Cassandra::cluster()->withContactPoints('192.168.7.184')->build();
$keyspace  = 'dvr';
$session   = $cluster->connect($keyspace);

$options     = new Cassandra\ExecutionOptions(array('consistency' => Cassandra::CONSISTENCY_LOCAL_ONE));

$variant='#EXTM3U'.PHP_EOL.'#EXT-X-VERSION:3'.PHP_EOL.'#EXT-X-STREAM-INF:BANDWIDTH=1558000,CODECS="avc1.100.32,mp4a.40.2",RESOLUTION=1024x576'.PHP_EOL.'chunklist_b1428000.m3u8'.PHP_EOL.'#EXT-X-STREAM-INF:BANDWIDTH=843000,CODECS="avc1.100.30,mp4a.40.2",RESOLUTION=512x288'.PHP_EOL.'chunklist_b778000.m3u8';

$batch = new Cassandra\BatchStatement(Cassandra::BATCH_LOGGED);
$batch->add("INSERT INTO dvr_bbc_world_variant_info (variant) VALUES ('$variant')");
$result = $session->execute($batch, $options);

?>
