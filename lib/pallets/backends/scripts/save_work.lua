-- Remove job from reliability queue
redis.call("LREM", KEYS[3], 0, ARGV[1])

-- Deincrement all jobs from the sorted set
local all_pending = redis.call("ZRANGE", KEYS[1], 0, -1)
for score, task in pairs(all_pending) do
  redis.call("ZINCRBY", KEYS[1], -1, task)
end

-- Queue jobs that are ready to be processed (their score is 0) and
-- remove queued jobs from the sorted set
local count = redis.call("ZCOUNT", KEYS[1], 0, 0)
if count > 0 then
  local work = redis.call("ZRANGEBYSCORE", KEYS[1], 0, 0)
  redis.call("LPUSH", KEYS[2], unpack(work))
  redis.call("ZREM", KEYS[1], unpack(work))
end
