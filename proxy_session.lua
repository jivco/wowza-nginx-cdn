--fast concaternation of strings
function listvalues(s)
    local t = { }
    for k,v in ipairs(s) do
        t[#t+1] = tostring(v)
    end
    return table.concat(t)
end

--read request
ngx.req.read_body()
 
--connect to redis
local redis = require "resty.redis"
local red = redis.new()
red.connect(red, '127.0.0.1', '6379')

--get variables from url         
local deviceid = ngx.var.arg_proxy_deviceid
local sessionid = ngx.var.arg_proxy_sessionid

--search in redis for active session         
--when user logs for the first time we set deviceid and sessionid in redis from login php script
local ProxySession = red:get(deviceid)

local hasProxySession = 0
if sessionid == ProxySession then
 hasProxySession = 1
end

--disconnect user if not supply correct data
if deviceid == nil or sessionid == nil or hasProxySession == 0 then
 ngx.say("No active session. Get out!")
 ngx.exit(ngx.HTTP_FORBIDDEN)
end

--make digest from deviceid and sessionid
local digestid = listvalues{deviceid, sessionid}

--get the number of maximul allowed sessions per user
local res, err = red:get("maxsessions")
if not res then
   ngx.say("failed to get maxsessions: ", err)
   ngx.exit(ngx.HTTP_FORBIDDEN)
end

if res == ngx.null then
   ngx.say("maxsessions not found")
   ngx.exit(ngx.HTTP_FORBIDDEN)
end

local maxsessions=tonumber(res)

--get the number of current user sessions
--when user logs for the first time we set digestid to 0 in redis from login php script
local res, err = red:get(digestid)
if not res then
   ngx.say("failed to get digestid: ", err)
   ngx.exit(ngx.HTTP_FORBIDDEN)
end

if res == ngx.null then
   ngx.say("digestid not found")
   ngx.exit(ngx.HTTP_FORBIDDEN)
end

local numsessions=tonumber(res)

if numsessions > maxsessions then
 ngx.say(listvalues{"Too many sessions: ", numsessions, " of ",maxsessions, " allowed for this time period for your user!"})
 ngx.exit(ngx.HTTP_FORBIDDEN)
end

numsessions=tonumber(numsessions + 1)

--increment user sessions number
local ok, err = red:set(digestid, numsessions)
if not ok then
   ngx.say("failed to increment user sessions: ", err)
   return
end

-- put it into the connection pool of size 100,
-- with 10 seconds max idle time
local ok, err = red:set_keepalive(10000, 100)
if not ok then
   ngx.say("failed to set keepalive: ", err)
   return
end

