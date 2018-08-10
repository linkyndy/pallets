$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pallets'
require 'pallets/cli'
require 'timecop'

Pallets.logger.level = Logger::FATAL
