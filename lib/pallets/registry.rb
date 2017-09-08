require 'active_support/core_ext/module/delegation'

module Pallets
  class Registry
    delegate :get, to: :adapter

    private

    def adapter
      # adapter set in config, initialize it
    end
  end
end
