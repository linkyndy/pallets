-- Remove job from reliability queue
redis.call("LREM", KEYS[1], 0, ARGV[1])
redis.call("ZREM", KEYS[2], ARGV[1])
