require 'pallets'

class HelloWorld < Pallets::Workflow
  task :echo
end

class Echo < Pallets::Task
  def run
    puts 'Hello World!'
  end
end

HelloWorld.new.run
