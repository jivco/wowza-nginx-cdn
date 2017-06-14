CREATE KEYSPACE DVR WITH REPLICATION = { 'class' : 'NetworkTopologyStrategy','sof1' : 1, 'usa1': 1 } AND DURABLE_WRITES = false;

CREATE TABLE variant_info (app text, tv text, bitrate int, codecs text, resolution text, PRIMARY KEY (app,tv,bitrate)) WITH gc_grace_seconds=86400 AND compaction = { 'class' :  'LeveledCompactionStrategy','sstable_size_in_mb':320, 'tombstone_threshold': '0.4'};

CREATE TABLE dvr_bbc_world_1428000_chunk_content (chunk_name text, time_id timeuuid, chunk_content blob, PRIMARY KEY (chunk_name, time_id)) WITH default_time_to_live=108000 AND gc_grace_seconds=86400 AND compaction = { 'class' :  'LeveledCompactionStrategy','sstable_size_in_mb':320, 'tombstone_threshold': '0.4'};
CREATE TABLE dvr_bbc_world_1428000_chunk_info (fake int, time_id timeuuid, chunk_name text, chunk_duration float, PRIMARY KEY ((fake), time_id)) WITH default_time_to_live=108000 AND gc_grace_seconds=86400 AND CLUSTERING ORDER BY ( time_id ASC ) AND compaction = { 'class' : 'LeveledCompactionStrategy','sstable_size_in_mb':320, 'tombstone_threshold': '0.4'};

CREATE TABLE dvr_bbc_world_778000_chunk_content (chunk_name text, time_id timeuuid, chunk_content blob, PRIMARY KEY (chunk_name, time_id)) WITH default_time_to_live=108000 AND gc_grace_seconds=86400 AND compaction = { 'class' :  'LeveledCompactionStrategy','sstable_size_in_mb':320, 'tombstone_threshold': '0.4'};
CREATE TABLE dvr_bbc_world_778000_chunk_info (fake int, time_id timeuuid, chunk_name text, chunk_duration float, PRIMARY KEY ((fake), time_id)) WITH default_time_to_live=108000 AND gc_grace_seconds=86400 AND CLUSTERING ORDER BY ( time_id ASC ) AND compaction = { 'class' : 'LeveledCompactionStrategy','sstable_size_in_mb':320, 'tombstone_threshold': '0.4'};

INSERT INTO variant_info (app, tv, bitrate, codecs, resolution) VALUES ('dvr', 'bbc_world', 1428000, 'avc1.100.32,mp4a.40.2', '1024x576');
INSERT INTO variant_info (app, tv, bitrate, codecs, resolution) VALUES ('dvr', 'bbc_world', 778000, 'avc1.100.30,mp4a.40.2', '512x288');
