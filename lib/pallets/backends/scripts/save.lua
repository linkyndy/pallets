-- Remove job from reliability queue
redis.call("LREM", KEYS[3], 0, ARGV[1])
redis.call("ZREM", KEYS[4], ARGV[1])

-- Add context log item to list
redis.call("RPUSH", KEYS[5], ARGV[2])

-- Decrement all jobs from the sorted set
local all_pending = redis.call("ZRANGE", KEYS[1], 0, -1)
for score, task in pairs(all_pending) do
  redis.call("ZINCRBY", KEYS[1], -1, task)
end

-- Queue jobs that are ready to be processed (their score is 0) and
-- remove queued jobs from sorted set
local count = redis.call("ZCOUNT", KEYS[1], 0, 0)
if count > 0 then
  local work = redis.call("ZRANGEBYSCORE", KEYS[1], 0, 0)
  redis.call("LPUSH", KEYS[2], unpack(work))
  redis.call("ZREM", KEYS[1], unpack(work))
end

-- Decrement counter and remove it together with the context log if all tasks have been processed (counter is 0)
redis.call("DECR", KEYS[6])
if tonumber(redis.call("GET", KEYS[6])) == 0 then
  redis.call("DEL", KEYS[5], KEYS[6])
end
