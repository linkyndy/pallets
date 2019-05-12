$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pallets'
require 'pallets/cli'
require 'pallets/middleware/appsignal_instrumenter'
require 'timecop'

Pallets.logger.level = Logger::FATAL
