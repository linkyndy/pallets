-- Remove job from reliability queue
redis.call("LREM", KEYS[2], 0, ARGV[3])

-- Add job and its retry time (score) to retry sorted set
redis.call("ZADD", KEYS[1], ARGV[1], ARGV[2])
