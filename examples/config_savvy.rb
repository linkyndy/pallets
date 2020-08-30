require 'pallets'

class AnnounceProcessing
  def self.call(worker, job, context)
    puts "Starting to process job..."
    yield
  end
end

Pallets.configure do |c|
  # Harness 4 Pallets workers per process
  c.concurrency = 4

  # The default one, though
  c.backend = :redis
  # Useful to connect to a hosted Redis instance. Takes all options `Redis.new`
  # accepts, like `db`, `timeout`, `host`, `port`, `password`, `sentinels`.
  # Check https://www.rubydoc.info/github/redis/redis-rb/Redis:initialize for
  # more details
  c.backend_args = { url: 'redis://127.0.0.1:6379/1' }
  # Use a maximum of 10 backend connections (Redis, in this case)
  c.pool_size = 10

  # A tad faster than JSON
  c.serializer = :msgpack

  # Allow 10 minutes for a job to process. After this, we assume the job did not
  # finish and we retry it
  c.job_timeout = 600
  # Jobs will be retried up to 5 times upon failure. After that, they will be
  # given up. Retry times are exponential and happen after: 7, 22, 87, 262, ...
  c.max_failures = 5

  # Job execution can be wrapped with middleware to provide custom logic.
  # Anything that responds to `call` would do
  c.middleware << AnnounceProcessing
end

class ConfigSavvy < Pallets::Workflow
  task 'Volatile'
  task 'Success' => 'Volatile'
end

class Volatile < Pallets::Task
  def run
    raise 'I am randomly failing' if [true, false].sample
  end
end

class Success < Pallets::Task
  def run
    puts 'I am executed after Volatile manages to successfully execute'
  end
end

ConfigSavvy.new.run
