require 'spec_helper'

describe Pallets::DSL::Workflow do
  # Set the subject to class that extends the DSL
  subject { Class.new { extend Pallets::DSL::Workflow } }

  let(:task_config) { {} }
  let(:graph) { instance_spy('Pallets::Graph') }

  before do
    allow(Pallets.configuration).to receive(:max_failures).and_return(3)
    # Stub external calls so we can test the DSL in isolation
    allow(subject).to receive(:task_config).and_return(task_config)
    allow(subject).to receive(:graph).and_return(graph)
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
      it 'identifies the name as the argument' do
        subject.class_eval { task 'Eat' }
        expect(graph).to have_received(:add).with('Eat', anything)
      end

      it 'does not identify any dependencies' do
        subject.class_eval { task 'Eat' }
        expect(graph).to have_received(:add).with(anything, [])
      end

      it 'handles classes' do
        stub_const('Eat', Class.new)
        subject.class_eval { task Eat }
        expect(graph).to have_received(:add).with('Eat', anything)
      end
    end

    context 'with a simple argument and with :depends_on' do
      it 'identifies the name as the argument' do
        subject.class_eval { task 'BuyFood', depends_on: 'EarnMoney' }
        expect(graph).to have_received(:add).with('BuyFood', anything)
      end

      it 'identifies dependencies from :depends_on' do
        subject.class_eval { task 'BuyFood', depends_on: 'EarnMoney' }
        expect(graph).to have_received(:add).with(anything, ['EarnMoney'])
      end

      it 'handles classes' do
        stub_const('BuyFood', Class.new)
        stub_const('EarnMoney', Class.new)
        subject.class_eval { task BuyFood, depends_on: EarnMoney }
        expect(graph).to have_received(:add).with('BuyFood', ['EarnMoney'])
      end

      it 'handles multiple dependencies' do
        subject.class_eval { task 'BuyFood', depends_on: ['EarnMoney', 'GoToShop'] }
        expect(graph).to have_received(:add).with(anything, ['EarnMoney', 'GoToShop'])
      end
    end

    context 'with a hash argument' do
      it 'identifies the name as the first key' do
        subject.class_eval { task 'Drink' => 'GetThirstiness' }
        expect(graph).to have_received(:add).with('Drink', anything)
      end

      it 'identifies dependencies as the first value' do
        subject.class_eval { task 'Drink' => 'GetThirstiness' }
        expect(graph).to have_received(:add).with(anything, ['GetThirstiness'])
      end

      it 'handles classes' do
        stub_const('Drink', Class.new)
        stub_const('GetThirstiness', Class.new)
        subject.class_eval { task Drink => GetThirstiness }
        expect(graph).to have_received(:add).with('Drink', ['GetThirstiness'])
      end

      it 'handles multiple dependencies' do
        subject.class_eval { task 'Drink' => ['GetThirstiness', 'BuyWater'] }
        expect(graph).to have_received(:add).with(anything, ['GetThirstiness', 'BuyWater'])
      end

      it 'discards dependencies from :depends_on' do
        subject.class_eval { task 'Drink' => 'GetThirstiness', depends_on: 'Hungry' }
        expect(graph).to have_received(:add).with(anything, ['GetThirstiness'])
      end
    end

    it "adds a task to the workflow's graph" do
      subject.class_eval { task 'One' }
      expect(graph).to have_received(:add).with('One', a_kind_of(Array))
    end

    it 'configures the task with the class name' do
      subject.class_eval { task 'Pay' }
      expect(subject.task_config).to match(
        'Pay' => a_hash_including('class_name' => 'Pay')
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
