CREATE KEYSPACE DVR WITH REPLICATION = { 'class' : 'NetworkTopologyStrategy','sof1' : 1, 'usa1': 1 } AND DURABLE_WRITES = false;

CREATE TABLE bnt1_480p_chunk_content (chunk_name text, time_id timeuuid, chunk_content blob, PRIMARY KEY (chunk_name, time_id)) WITH default_time_to_live=28800 AND gc_grace_seconds=86400 AND compaction = { 'class' :  'LeveledCompactionStrategy','tombstone_compaction_interval':3600  };
CREATE TABLE bnt1_480p_chunk_info (fake int, time_id timeuuid, chunk_name text, chunk_duration float, PRIMARY KEY ((fake), time_id)) WITH default_time_to_live=28800 AND gc_grace_seconds=86400 AND CLUSTERING ORDER BY ( time_id ASC ) AND compaction = { 'class' :  'LeveledCompactionStrategy','tombstone_compaction_interval':3600  };
CREATE TABLE bnt1_480p_playlist_all (fake int, time_id timeuuid, playlist text, PRIMARY KEY ((fake), time_id)) WITH default_time_to_live=30 AND gc_grace_seconds=86400 AND CLUSTERING ORDER BY ( time_id ASC ) AND compaction = { 'class' :  'LeveledCompactionStrategy','tombstone_compaction_interval':3600  };

truncate table bnt1_480p_chunk_content;
truncate table bnt1_480p_chunk_info;
truncate table bnt1_480p_playlist_all;

drop table bnt1_480p_chunk_content;
drop table bnt1_480p_chunk_info;
drop table bnt1_480p_playlist_all;
