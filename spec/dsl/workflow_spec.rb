require 'spec_helper'

describe Pallets::DSL::Workflow do
  # Set the subject to workflow class that extends the DSL
  subject { Class.new(Pallets::Workflow) { extend Pallets::DSL::Workflow } }

  before do
    allow(Pallets.configuration).to receive(:max_failures).and_return(3)
  end

  describe '#task' do
    context 'with no arguments' do
      it 'raises an error' do
        expect do
          subject.class_eval { task }
        end.to raise_error(ArgumentError)
      end
    end

    context 'with a simple argument' do
      it 'identifies the name as the argument and no dependencies' do
        expect(subject.graph).to receive(:add).with('Eat', [])
        subject.class_eval { task 'Eat' }
      end

      context 'and with :as' do
        it 'identifies the name as :as and no dependencies' do
          expect(subject.graph).to receive(:add).with('ActuallyEat', [])
          subject.class_eval { task 'Eat', as: 'ActuallyEat' }
        end
      end

      it 'handles classes' do
        stub_const('Eat', Class.new)
        expect(subject.graph).to receive(:add).with('Eat', [])
        subject.class_eval { task Eat }
      end
    end

    context 'with a simple argument and with :depends_on' do
      it 'identifies the name as the argument and dependencies from :depends_on' do
        expect(subject.graph).to receive(:add).with('BuyFood', ['EarnMoney'])
        subject.class_eval { task 'BuyFood', depends_on: 'EarnMoney' }
      end

      context 'and with :as' do
        it 'identifies the name as :as and dependencies from :depends_on' do
          expect(subject.graph).to receive(:add).with('ActuallyBuyFood', ['EarnMoney'])
          subject.class_eval { task 'BuyFood', as: 'ActuallyBuyFood', depends_on: 'EarnMoney' }
        end
      end

      it 'handles classes' do
        stub_const('BuyFood', Class.new)
        stub_const('EarnMoney', Class.new)
        expect(subject.graph).to receive(:add).with('BuyFood', ['EarnMoney'])
        subject.class_eval { task BuyFood, depends_on: EarnMoney }
      end

      it 'handles multiple dependencies' do
        expect(subject.graph).to receive(:add).with('BuyFood', ['EarnMoney', 'GoToShop'])
        subject.class_eval { task 'BuyFood', depends_on: ['EarnMoney', 'GoToShop'] }
      end
    end

    context 'with a hash argument' do
      it 'identifies the name as the first key and dependencies as the first value' do
        expect(subject.graph).to receive(:add).with('Drink', ['GetThirstiness'])
        subject.class_eval { task 'Drink' => 'GetThirstiness' }
      end

      context 'and with :as' do
        it 'identifies the name as :as and dependencies as the first value' do
          expect(subject.graph).to receive(:add).with('ActuallyDrink', ['GetThirstiness'])
          subject.class_eval { task 'Drink', as: 'ActuallyDrink', depends_on: 'GetThirstiness' }
        end
      end

      it 'handles classes' do
        stub_const('Drink', Class.new)
        stub_const('GetThirstiness', Class.new)
        expect(subject.graph).to receive(:add).with('Drink', ['GetThirstiness'])
        subject.class_eval { task Drink => GetThirstiness }
      end

      it 'handles multiple dependencies' do
        expect(subject.graph).to receive(:add).with('Drink', ['GetThirstiness', 'BuyWater'])
        subject.class_eval { task 'Drink' => ['GetThirstiness', 'BuyWater'] }
      end

      it 'discards dependencies from :depends_on' do
        expect(subject.graph).to receive(:add).with('Drink', ['GetThirstiness'])
        subject.class_eval { task 'Drink' => 'GetThirstiness', depends_on: 'Hungry' }
      end
    end

    it 'configures the task with the class name' do
      subject.class_eval { task 'Pay' }
      expect(subject.task_config).to match(
        'Pay' => a_hash_including('task_class' => 'Pay')
      )
    end

    it 'configures the task with the workflow class name' do
      subject.class_eval { task 'Pay' }
      expect(subject.task_config).to match(
        'Pay' => a_hash_including('workflow_class' => 'Class')
      )
    end

    context 'with a :max_failures option provided' do
      it 'configures the task with the given value' do
        subject.class_eval { task 'Pay', max_failures: 1 }
        expect(subject.task_config).to match(
          'Pay' => a_hash_including('max_failures' => 1)
        )
      end
    end

    context 'without a :max_failures option provided' do
      it 'configures the task with a default value' do
        subject.class_eval { task 'Pay' }
        expect(subject.task_config).to match(
          'Pay' => a_hash_including('max_failures' => 3)
        )
      end
    end

    it 'returns nil' do
      expect(subject.class_eval { task :one }).to be_nil
    end
  end
end
