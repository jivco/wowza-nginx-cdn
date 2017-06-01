<?php

date_default_timezone_set('UTC');

$app=$argv[1];
$tv=$argv[2];
$res=$argv[3];
$playlist_path=$argv[4];
$chunk_filename=$argv[5];
$chunk_duration=$argv[6];

$cluster   = Cassandra::cluster()->withContactPoints('192.168.7.184')->build();
$keyspace  = 'dvr';
$session   = $cluster->connect($keyspace);

$fileContent = file_get_contents("$playlist_path/$chunk_filename");
$blob = new \Cassandra\Blob($fileContent);
$chunk_content = $blob->bytes();

$table_chunk_content=$app.'_'.$tv.'_'.$res.'_chunk_content';
$table_chunk_info=$app.'_'.$tv.'_'.$res.'_chunk_info';

$options     = new Cassandra\ExecutionOptions(array('consistency' => Cassandra::CONSISTENCY_LOCAL_ONE));

$batch = new Cassandra\BatchStatement(Cassandra::BATCH_LOGGED);
$batch->add("INSERT INTO $table_chunk_content (time_id, chunk_name, chunk_content) VALUES (now(), '$chunk_filename', $chunk_content)");
$batch->add("INSERT INTO $table_chunk_info (fake, time_id, chunk_name, chunk_duration) VALUES (1, now(), '$chunk_filename', $chunk_duration)");
$result = $session->execute($batch, $options);

?>
