-- Add all jobs to sorted set
local eta = redis.call("ZADD", KEYS[1], unpack(ARGV))

-- Set ETA key; this is merely the number of jobs that need to be processed
redis.call("SET", KEYS[3], eta)

-- Queue jobs that are ready to be processed (their score is 0) and
-- remove queued jobs from the sorted set
local work = redis.call("ZRANGEBYSCORE", KEYS[1], 0, 0)
if #work > 0 then
  redis.call("LPUSH", KEYS[2], unpack(work))
  redis.call("ZREM", KEYS[1], unpack(work))
end
