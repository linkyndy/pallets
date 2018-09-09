require 'spec_helper'

describe Pallets::Manager do
  # Be explicit in the number of workers that we test
  subject { Pallets::Manager.new(concurrency: 2) }

  let(:scheduler_class) { class_double('Pallets::Scheduler').as_stubbed_const }
  let(:scheduler) { instance_spy('Pallets::Scheduler') }
  let(:worker_class) { class_double('Pallets::Worker').as_stubbed_const }
  let(:worker) { instance_spy('Pallets::Worker') }
  let(:another_worker) { instance_spy('Pallets::Worker') }
  let(:yet_another_worker) { instance_spy('Pallets::Worker') }

  before do
    allow(scheduler_class).to receive(:new).and_return(scheduler)
    allow(worker_class).to receive(:new).and_return(worker, another_worker, yet_another_worker)
    # Simulate workers shutting down gracefully
    allow(worker).to receive(:graceful_shutdown) do
      subject.workers.delete(worker)
    end
    allow(another_worker).to receive(:graceful_shutdown) do
      subject.workers.delete(another_worker)
    end
  end

  it 'initializes the correct number of workers' do
    manager = Pallets::Manager.new(concurrency: 10)
    expect(manager.workers.size).to eq(10)
  end

  describe '#start' do
    it 'starts all workers' do
      subject.start
      expect(worker).to have_received(:start)
      expect(another_worker).to have_received(:start)
    end

    it 'starts the scheduler' do
      subject.start
      expect(scheduler).to have_received(:start)
    end
  end

  describe '#shutdown' do
    subject { Pallets::Manager.new(concurrency: 2) }

    before do
      # Do not *actually* sleep
      allow(subject).to receive(:sleep)
    end

    it 'gracefully shuts down all workers' do
      subject.shutdown
      expect(worker).to have_received(:graceful_shutdown)
      expect(another_worker).to have_received(:graceful_shutdown)
    end

    it 'shuts down the scheduler' do
      subject.shutdown
      expect(scheduler).to have_received(:shutdown)
    end

    context 'with busy workers' do
      before do
        # Simulate busy workers
        allow(worker).to receive(:graceful_shutdown)
        allow(another_worker).to receive(:graceful_shutdown)
      end

      it 'waits a given number of seconds before hard shutting down workers' do
        subject.shutdown
        expect(subject).to have_received(:sleep).with(1).exactly(10).times
      end

      it 'hard shuts down all workers' do
        subject.shutdown
        expect(worker).to have_received(:hard_shutdown)
        expect(another_worker).to have_received(:hard_shutdown)
      end

      it 'waits for half a second after hard shutting down workers' do
        subject.shutdown
        expect(subject).to have_received(:sleep).with(0.5).once
      end
    end

    context 'with finished workers' do
      it 'returns immediately' do
        subject.shutdown
        expect(subject).not_to have_received(:sleep)
      end

      it 'does not hard shutdown all workers' do
        subject.shutdown
        expect(worker).not_to have_received(:hard_shutdown)
        expect(another_worker).not_to have_received(:hard_shutdown)
      end
    end
  end

  describe '#remove_worker' do
    it 'removes given worker' do
      subject.remove_worker(worker)
      expect(subject.workers).not_to include(worker)
    end

    it 'decreases the number of workers' do
      expect do
        subject.remove_worker(worker)
      end.to change { subject.workers.size }.by(-1)
    end
  end

  describe '#replace_worker' do
    it 'removes given worker' do
      subject.replace_worker(worker)
      expect(subject.workers).not_to include(worker)
    end

    it 'adds a new worker' do
      subject.replace_worker(worker)
      expect(subject.workers).to include(yet_another_worker)
    end

    it 'maintains the number of workers' do
      expect do
        subject.replace_worker(worker)
      end.not_to change { subject.workers.size }
    end
  end
end
