require 'active_support/core_ext/module/delegation'

module Pallets
  class ProductionLine
    delegate :pick, to: :adapter

    private

    def adapter
      # adapter set in config, initialize it
    end
  end
end
