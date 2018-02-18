require 'pallets'

class ProcessOrder < Pallets::Workflow
  task :buy
  task :pay => :buy
  task :dispatch_payment, depends_on: :pay
  task :ship, depends_on: :pay
  task :send_email, depends_on: :pay
  task :mark_as_complete => [:pay, :send_email]
  task :done => :mark_as_complete
end

class Buy < Pallets::Task; def run; puts 'BUY'; sleep(1); end; end
class Pay < Pallets::Task; def run; puts 'PAY'; sleep(2); end; end
class DispatchPayment < Pallets::Task; def run; puts 'DISPATCH PAYMENT'; sleep(1); end; end
class Ship < Pallets::Task; def run; puts 'SHIP'; sleep(1); end; end
class SendEmail < Pallets::Task; def run; puts 'SENDEMAIL'; sleep(1.2); end; end
class MarkAsComplete < Pallets::Task; def run; puts 'MARKASCOMPLETE'; sleep(5); end; end
class Done < Pallets::Task; def run; puts 'DONE'; sleep(1); end; end

workflow = ProcessOrder.new(order_id: 123, method: :visa)
workflow.start

# be ruby -e 'require "pallets"; require "./test"; manager = Pallets::Manager.new; manager.start; sleep(10); manager.stop'

# statuses:
# * 00 - pending
# * 01 - running
# * 10 - finished
# * 11 - failed
#
# BITFIELD bla SET u12 0 0 - or SET u2 0 0 SET u2 1 0 ...
# BITFIELD bla INCRBY u2 3 1 - set next status on 4th job
# BITFIELD bla GET u2 2 - get status of 3rd job
#
# create workflow with jobs that have an offset. bitfield for each workflow, everytime a job is handled, bitfield is updated for workflow for given job offset
