require 'pallets'

class Anonymous < Pallets::Task
  def run
    puts 'This is anonymous!'
  end
end

workflow = Pallets::Workflow.build do
  task 'Anonymous'
end

workflow.new.run
