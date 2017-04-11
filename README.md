# wowza-nginx-cdn
Some config files and POC code to make Wowza work with large DVR window and many users.

 - openresty-cahe-wowza-gzip-hash-lua.conf - 
It's working config of nginx cache using openresty. The high load of Wowza is due to concaternating auth string to every row of a playlist so we are using lua to do that. Basically we intercept wowza response and modify it.
