require 'pallets'
require 'pallets/middleware/appsignal_instrumenter'

Appsignal.config = Appsignal::Config.new(
  File.expand_path(File.dirname(__FILE__)),
  "development"
)
Appsignal.start
Appsignal.start_logger

Pallets.configure do |c|
  c.middleware << Pallets::Middleware::AppsignalInstrumenter
end

class Appsignaling < Pallets::Workflow
  task 'Signaling'
  task 'ReturningSignal' => 'Signaling'
end

class Signaling < Pallets::Task
  def run
    puts context['signal']
  end
end

class ReturningSignal < Pallets::Task
  def run
    puts 'Ho!'
  end
end

Appsignaling.new(signal: 'Hey').run
