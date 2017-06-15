CREATE KEYSPACE DVR WITH REPLICATION = { 'class' : 'NetworkTopologyStrategy','sof1' : 1, 'usa1': 1 } AND DURABLE_WRITES = false;

CREATE TABLE dvr.variant_info (
    app text,
    tv text,
    bitrate int,
    codecs text,
    resolution text,
    PRIMARY KEY (app, tv, bitrate)
) WITH CLUSTERING ORDER BY (tv ASC, bitrate ASC)
    AND bloom_filter_fp_chance = 0.01
    AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
    AND comment = ''
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.TimeWindowCompactionStrategy', 'compaction_window_size': '1', 'compaction_window_unit': 'HOURS', 'max_threshold': '32', 'min_threshold': '4'}
    AND compression = {'chunk_length_in_kb': '64', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'}
    AND crc_check_chance = 1.0
    AND dclocal_read_repair_chance = 0.1
    AND default_time_to_live = 0
    AND gc_grace_seconds = 60
    AND max_index_interval = 2048
    AND memtable_flush_period_in_ms = 0
    AND min_index_interval = 128
    AND read_repair_chance = 0.0
    AND speculative_retry = '99PERCENTILE';

CREATE TABLE dvr.dvr_bbc_world_1428000_chunk_info (
    fake int,
    time_id timeuuid,
    chunk_duration float,
    chunk_name text,
    PRIMARY KEY (fake, time_id)
) WITH CLUSTERING ORDER BY (time_id ASC)
    AND bloom_filter_fp_chance = 0.01
    AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
    AND comment = ''
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.TimeWindowCompactionStrategy', 'compaction_window_size': '1', 'compaction_window_unit': 'HOURS', 'max_threshold': '32', 'min_threshold': '4'}
    AND compression = {'chunk_length_in_kb': '64', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'}
    AND crc_check_chance = 1.0
    AND dclocal_read_repair_chance = 0.1
    AND default_time_to_live = 86400
    AND gc_grace_seconds = 60
    AND max_index_interval = 2048
    AND memtable_flush_period_in_ms = 0
    AND min_index_interval = 128
    AND read_repair_chance = 0.0
    AND speculative_retry = '99PERCENTILE';


CREATE TABLE dvr.dvr_bbc_world_1428000_chunk_content (
    chunk_name text,
    time_id timeuuid,
    chunk_content blob,
    PRIMARY KEY (chunk_name, time_id)
) WITH CLUSTERING ORDER BY (time_id ASC)
    AND bloom_filter_fp_chance = 0.01
    AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
    AND comment = ''
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.TimeWindowCompactionStrategy', 'compaction_window_size': '1', 'compaction_window_unit': 'HOURS', 'max_threshold': '32', 'min_threshold': '4'}
    AND compression = {'chunk_length_in_kb': '64', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'}
    AND crc_check_chance = 1.0
    AND dclocal_read_repair_chance = 0.1
    AND default_time_to_live = 86400
    AND gc_grace_seconds = 60
    AND max_index_interval = 2048
    AND memtable_flush_period_in_ms = 0
    AND min_index_interval = 128
    AND read_repair_chance = 0.0
    AND speculative_retry = '99PERCENTILE';

INSERT INTO variant_info (app, tv, bitrate, codecs, resolution) VALUES ('dvr', 'bbc_world', 1428000, 'avc1.100.32,mp4a.40.2', '1024x576');
INSERT INTO variant_info (app, tv, bitrate, codecs, resolution) VALUES ('dvr', 'bbc_world', 778000, 'avc1.100.30,mp4a.40.2', '512x288');
