module Pallets
  # Generic class for all Pallets-related errors
  class PalletsError < StandardError
  end

  # Raised when a workflow is not properly defined
  class WorkflowError < PalletsError
  end

  # Raised when Pallets needs to shutdown
  # NOTE: Do not rescue it!
  class Shutdown < Interrupt
  end
end
