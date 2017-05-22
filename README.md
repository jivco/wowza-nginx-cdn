# wowza-nginx-cdn
Some config files and POC code to make Wowza work with large DVR window and many users.

 - openresty-cahe-wowza-gzip-hash-lua.conf - 
It's working config of nginx cache using openresty. The high load of Wowza is due to concaternating auth string to every row of a playlist so we are using lua to do that. Basically we intercept wowza's response and modify it on the fly. Wowza must be configured in Live HTTP origin mode (origin for non-wowza edges).

# cassandra-cdn
Some config files and POC code to use Apache Cassandra as distributed storage for HLS chunks accross multiple datacenters and scripts for converting/transcoding UDP MPEG-TS to HLS and vice versa. The idea is take from Globo.com’s Live Video Platform for FIFA World Cup ’14.

- cassandra -> congigs for Apache Cassandra
- dvr -> a Lua module to optimize Openresty config. This approach will be the most efficient as it will avoid re-creating the cluster variable on each request and will preserve the cached state of your load-balancing policy and prepared statements directly in the Lua land.
- openresty -> nginx config
- scripts -> converting/transcoding UDP MPEG-TS to HLS and vice versa and storing chunks in Apache Cassandra
- system -> some tips for instalation of DataStax's PHP driver and system config.
- test - some scripts to test if everything is working properly.
