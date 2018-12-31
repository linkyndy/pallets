-- Set counter key
local number_of_jobs = table.remove(ARGV)
redis.call("SET", KEYS[4], number_of_jobs)

-- Add initial context log item to set
local context_log = table.remove(ARGV)
redis.call("RPUSH", KEYS[3], context_log)

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
