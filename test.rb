require 'pallets'

class ProcessOrder < Pallets::Workflow
  task :buy
  task :pay => :buy
  task :ship, depends_on: :pay
  task :send_email, depends_on: :pay
  task :mark_as_complete => [:pay, :send_email]
  task :done => :mark_as_complete
end

class Buy < Pallets::Task; def run; puts 'BUY'; sleep(1); end; end
class Pay < Pallets::Task; def run; puts 'PAY'; sleep(1); end; end
class Ship < Pallets::Task; def run; puts 'SHIP'; sleep(1); end; end
class SendEmail < Pallets::Task; def run; puts 'SENDEMAIL'; sleep(1); end; end
class MarkAsComplete < Pallets::Task; def run; puts 'MARKASCOMPLETE'; sleep(1); end; end
class Done < Pallets::Task; def run; puts 'DONE'; sleep(1); end; end

workflow = ProcessOrder.new(order_id: 123, method: :visa)
workflow.start

# be ruby -e 'require "pallets"; require "./test"; manager = Pallets::Manager.new; manager.start; sleep(10); manager.stop'
