-- NOTE: We store the job as the last argument passed to this script because it
--       is more efficient to pop in Lua than shift
local job = table.remove(ARGV)
-- Remove job from reliability queue
redis.call("LREM", KEYS[3], 0, job)
redis.call("ZREM", KEYS[4], job)

-- Update context hash with buffer
if #ARGV > 0 then
  redis.call("HMSET", KEYS[5], unpack(ARGV))
end

-- Decrement jobs from the sorted set by applying a jobmask
redis.call("ZUNIONSTORE", KEYS[1], 2, KEYS[1], KEYS[7])
redis.call("DEL", KEYS[7])

-- Queue jobs that are ready to be processed (their score is 0) and
-- remove queued jobs from sorted set
local work = redis.call("ZRANGEBYSCORE", KEYS[1], 0, 0)
if #work > 0 then
  redis.call("LPUSH", KEYS[2], unpack(work))
  redis.call("ZREM", KEYS[1], unpack(work))
end

-- Decrement ETA and remove it together with the context and jobmasks if all
-- tasks have been processed (ETA is 0) or if workflow has been given up (ETA is -1)
local remaining = redis.call("DECR", KEYS[6])
if remaining <= 0 then
  redis.call("DEL", KEYS[5], KEYS[6], KEYS[8])
end
