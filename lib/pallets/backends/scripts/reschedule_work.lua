-- Queue reliability queue jobs that are ready to be retried (their score is
-- below given value) and remove jobs from sorted set and list
-- TODO: Add limit of items to get
local count = redis.call("ZCOUNT", KEYS[1], "-inf", ARGV[1])
if count > 0 then
  local work = redis.call("ZRANGEBYSCORE", KEYS[1], "-inf", ARGV[1])
  redis.call("LPUSH", KEYS[4], unpack(work))
  redis.call("ZREMRANGEBYSCORE", KEYS[1], "-inf", ARGV[1])
  for _, job in pairs(work) do
    redis.call("LREM", KEYS[2], 0, job)
  end
end

-- Queue jobs that are ready to be retried (their score is below given value) and
-- remove jobs from sorted set
-- TODO: Add limit of items to get
local count = redis.call("ZCOUNT", KEYS[3], "-inf", ARGV[1])
if count > 0 then
  local work = redis.call("ZRANGEBYSCORE", KEYS[3], "-inf", ARGV[1])
  redis.call("LPUSH", KEYS[4], unpack(work))
  redis.call("ZREMRANGEBYSCORE", KEYS[3], "-inf", ARGV[1])
end
