require 'sidekiq'

class Bla
  include Sidekiq::Worker

  def perform
    puts 'here'
    # raise
    sleep 50
  end
end
