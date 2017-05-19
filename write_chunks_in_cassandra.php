<?php

function get_playlist_start_time($ttl) {
	return date(DATE_ATOM, time() - $ttl);
}

date_default_timezone_set('UTC');

$playlist_name=$argv[1];
$playlist_path=$argv[2];
$chunk_filename=$argv[3];
$chunk_duration=$argv[4];

$cluster   = Cassandra::cluster()->withContactPoints('93.123.36.180')->build();
$keyspace  = 'dvr';
$session   = $cluster->connect($keyspace);

$fileContent = file_get_contents("$playlist_path/$chunk_filename");
$blob = new \Cassandra\Blob($fileContent);
$chunk_content = $blob->bytes();

$table_chunk_content=$playlist_name.'_chunk_content';
$table_chunk_info=$playlist_name.'_chunk_info';
$table_playlist_all=$playlist_name.'_playlist_all';
$playlist_all_TTL='14400';

$options     = new Cassandra\ExecutionOptions(array('consistency' => Cassandra::CONSISTENCY_LOCAL_ONE));

$playlist_all_start_time=get_playlist_start_time($playlist_all_TTL);

$qry="SELECT fake, chunk_duration, chunk_name FROM $table_chunk_info WHERE time_id>minTimeuuid('$playlist_all_start_time') ALLOW FILTERING";
$statement   = new Cassandra\SimpleStatement($qry);
$result = $session->execute($statement, $options);

$playlist_all_tmp1='';
$first_cunk=true;
$first_chunk_num='';
$targetduration='';

foreach ($result as $row) {
 	 if ($first_cunk) {
		 $first_chunk_num_tmp1=explode("_", $row['chunk_name']);
		 $first_chunk_num_tmp2=explode(".ts", end($first_chunk_num_tmp1));
		 $first_chunk_num=$first_chunk_num_tmp2[0];
		 $targetduration=ceil($row['chunk_duration']);
		 $first_cunk=false;
   }
		$playlist_all_tmp1.=PHP_EOL.'#EXTINF:'.$row['chunk_duration'].','.PHP_EOL.$row['chunk_name'];
}
$playlist_all_tmp2='#EXTM3U'.PHP_EOL.'#EXT-X-TARGETDURATION:'.$targetduration.PHP_EOL.'#EXT-X-ALLOW-CACHE:YES'.PHP_EOL.'#EXT-X-VERSION:3'.PHP_EOL.'#EXT-X-MEDIA-SEQUENCE:'.$first_chunk_num;

$playlist_all=$playlist_all_tmp2.$playlist_all_tmp1;

$batch = new Cassandra\BatchStatement(Cassandra::BATCH_LOGGED);
$batch->add("INSERT INTO $table_playlist_all (fake, time_id, playlist) VALUES (1, now(), '$playlist_all')");
$batch->add("INSERT INTO $table_chunk_content (time_id, chunk_name, chunk_content) VALUES (now(), '$chunk_filename', $chunk_content)");
$batch->add("INSERT INTO $table_chunk_info (fake, time_id, chunk_name, chunk_duration) VALUES (1, now(), '$chunk_filename', $chunk_duration)");
$result = $session->execute($batch, $options);

?>

