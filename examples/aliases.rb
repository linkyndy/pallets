require 'pallets'

class Aliases < Pallets::Workflow
  task 'StartSmtpServer'
  task 'SendEmail', as: 'SayHello', depends_on: 'StartSmtpServer'
  task 'SendEmail', as: 'SayGoodbye', depends_on: 'StartSmtpServer'
  task 'StopSmtpServer' => ['SayHello', 'SayGoodbye']
end

class StartSmtpServer < Pallets::Task
  def run
    puts "Starting SMTP server..."
  end
end

class SendEmail < Pallets::Task
  def run
    puts "* sending e-mail"
  end
end

class StopSmtpServer < Pallets::Task
  def run
    puts "Stopped SMTP server"
  end
end

Aliases.new.run
