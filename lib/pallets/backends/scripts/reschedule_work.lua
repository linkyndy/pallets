-- Queue jobs that somehow could not be processed (due to worker errors) and are
-- on the reliability queue
-- TODO: Do more than one, but with a limit
-- !!!! be aware to wait a bit, otherwise one that is processed will be processed again in the same time
-- redis.call("RPOPLPUSH", KEYS[1], KEYS[3])

-- Queue jobs that are ready to be retried (their score is below given value) and
-- remove jobs from sorted set
-- TODO: Add limit of items to get
local count = redis.call("ZCOUNT", KEYS[2], "-inf", ARGV[1])
if count > 0 then
  local work = redis.call("ZRANGEBYSCORE", KEYS[2], "-inf", ARGV[1])
  redis.call("LPUSH", KEYS[3], unpack(work))
  redis.call("ZREMRANGEBYSCORE", KEYS[2], "-inf", ARGV[1])
end
