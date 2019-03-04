require 'pallets'

class DoGroceries < Pallets::Workflow
  task 'EnterShop'
  task 'GetShoppingCart' => 'EnterShop'
  task 'PutMilk' => 'GetShoppingCart'
  task 'PutBread' => 'GetShoppingCart'
  task 'Pay' => ['PutMilk', 'PutBread']
  task 'GoHome' => 'Pay'
end

class EnterShop < Pallets::Task
  def run
    puts "Entering #{context['shop_name']}"
  end
end

class GetShoppingCart < Pallets::Task
  def run
    puts "Where's that 50 cent coin??"
    context['need_to_return_coin'] = true
  end
end

class PutMilk < Pallets::Task
  def run
    puts "Whole or half? Hmm..."
    sleep 1
  end
end

class PutBread < Pallets::Task
  def run
    puts "Got the bread"
  end
end

class Pay < Pallets::Task
  def run
    puts "Paying by #{context['pay_by']}"
    sleep 2
  end
end

class GoHome < Pallets::Task
  def run
    puts "Done!!"

    if context['need_to_return_coin']
      puts '...forgot to get my coin back...'
    end
  end
end

DoGroceries.new(shop_name: 'Pallet Shop', pay_by: :card).run
