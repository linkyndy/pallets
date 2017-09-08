require 'spec_helper'

describe Pallets::DSL::Workflow do
  # Set the subject to class that extends the DSL
  subject { Class.new { extend Pallets::DSL::Workflow } }

  let(:graph) { instance_spy('Pallets::Graph') }

  before do
    # Stub external calls so we can test the DSL in isolation
    allow(subject).to receive(:graph).and_return(graph)
  end

  describe '#task' do
    context 'with a positional argument' do
      it 'identifies the name as the positional argument' do
        subject.class_eval { task :eat }
        expect(graph).to have_received(:add).with(:eat, anything)
      end

      it 'does not identify any dependencies' do
        subject.class_eval { task :eat }
        expect(graph).to have_received(:add).with(anything, [])
      end
    end

    context 'with a positional argument and with a hash argument' do
      it 'identifies the name as the positional argument' do
        subject.class_eval { task :buy_food, if: :hungry? }
        expect(graph).to have_received(:add).with(:buy_food, anything)
      end

      context 'having the :depends_on key' do
        it 'identifies dependencies from the :depends_on key' do
          subject.class_eval { task :buy_food, depends_on: :earn_money }
          expect(graph).to have_received(:add).with(anything, [:earn_money])
        end

        it 'handles multiple dependencies' do
          subject.class_eval { task :buy_food, depends_on: [:earn_money, :go_to_shop] }
          expect(graph).to have_received(:add).with(anything, [:earn_money, :go_to_shop])
        end
      end

      context 'not having the :depends_on key' do
        it 'does not identify any dependencies' do
          subject.class_eval { task :one, if: :hungry? }
          expect(graph).to have_received(:add).with(anything, [])
        end
      end
    end

    context 'with a hash argument' do
      it 'identifies the name as the first key' do
        subject.class_eval { task :drink => :get_thirstiness }
        expect(graph).to have_received(:add).with(:drink, anything)
      end

      it 'identifies dependencies as the first value' do
        subject.class_eval { task :drink => :get_thirstiness }
        expect(graph).to have_received(:add).with(anything, [:get_thirstiness])
      end

      it 'discards dependencies specified in a :depends_on key' do
        subject.class_eval { task :drink => :get_thirstiness, depends_on: :hungry }
        expect(graph).to have_received(:add).with(anything, [:get_thirstiness])
      end
    end

    it "adds a task to the workflow's graph" do
      subject.class_eval { task :one }
      expect(graph).to have_received(:add).with(any_args)
    end

    it 'returns nil' do
      expect(subject.class_eval { task :one }).to be_nil
    end
  end
end
