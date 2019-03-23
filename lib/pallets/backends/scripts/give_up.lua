-- Remove job from reliability queue
redis.call("LREM", KEYS[2], 0, ARGV[3])
redis.call("ZREM", KEYS[3], ARGV[3])

-- Add job and its cleanup time (score) to failed sorted set
redis.call("ZADD", KEYS[1], ARGV[1], ARGV[2])

-- Schedule cleanup for related keys (workflow queue, context and ETA), if given
if KEYS[4] and KEYS[5] and KEYS[6] then
  redis.call("EXPIREAT", KEYS[4], ARGV[5])
  redis.call("EXPIREAT", KEYS[5], ARGV[5])
  redis.call("EXPIREAT", KEYS[6], ARGV[5])
end

-- Remove any jobs that have been given up long enough ago (their score is
-- below given value)
redis.call("ZREMRANGEBYSCORE", KEYS[1], "-inf", ARGV[4])
