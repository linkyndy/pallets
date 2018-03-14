-- Add all jobs to sorted set
redis.call("ZADD", KEYS[1], unpack(ARGV))
-- Queue jobs that are ready to be processed (their score is 0) and
-- remove queued jobs from the sorted set
local count = redis.call("ZCOUNT", KEYS[1], 0, 0)
if count > 0 then
  local work = redis.call("ZRANGEBYSCORE", KEYS[1], 0, 0)
  redis.call("LPUSH", KEYS[2], unpack(work))
  redis.call("ZREM", KEYS[1], unpack(work))
end
