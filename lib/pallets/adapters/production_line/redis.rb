module Pallets
  module Adapters
    module ProductionLine
      class Redis
        def pick
          Pallets.redis.brpop('queue')
        end
      end
    end
  end
end
