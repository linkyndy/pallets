class CLI
  def initialize
    @manager = Thread.new { sleep }
    @signal_queue = Queue.new

    setup_signal_handlers
  end

  def run
    # @manager.start
    loop do
      signal = @signal_queue.pop # This doesn't unblock!
      handle_signal(signal)
    end
  rescue Interrupt
    # @manager.shutdown
    exit
  end

  private

  def handle_signal(signal)
    case signal
    when 'INT'
      raise Interrupt
    end
  end

  def setup_signal_handlers
    %w(INT).each do |signal|
      trap signal do
        @signal_queue.push signal # This works. @signal_queue.size is incremented
      end
    end
  end
end
