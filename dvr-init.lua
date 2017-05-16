package.cpath = package.cpath .. ";/usr/lib64/lua/5.1/?.so"
local cassandra = require "cassandra"
local Cluster = require "resty.cassandra.cluster"
local dc_rr = require "resty.cassandra.policies.lb.dc_rr"
local policy = dc_rr.new("sof1")

-- cluster instance as an upvalue
local cluster

local _M = {}

function _M.init_cluster(...)
  cluster = assert(Cluster.new(...))

  -- we also retrieve the cluster's nodes informations early, to avoid
  -- slowing down our first incoming request, which would have triggered
  -- a refresh should this not be done already.
  assert(cluster:refresh())
end

function _M.execute(...)
  return cluster:execute(...)
end

return _M
