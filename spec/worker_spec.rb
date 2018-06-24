require 'spec_helper'

describe Pallets::Worker do
  subject { Pallets::Worker.new(manager) }

  let(:manager) { instance_spy('Pallets::Manager') }

  describe '#start' do
    before do
      allow(Thread).to receive(:new).and_yield
      allow(subject).to receive(:work)
    end

    it 'creates a separate thread' do
      subject.start
      expect(Thread).to have_received(:new)
    end

    it 'starts working' do
      subject.start
      expect(subject).to have_received(:work)
    end
  end

  describe '#graceful_shutdown' do
    it 'signals it needs to stop' do
      expect { subject.graceful_shutdown }.to change { subject.needs_to_stop? }.from(false).to(true)
    end
  end

  describe '#hard_shutdown' do
    context 'when started' do
      let(:thread) { instance_spy('Thread') }

      before do
        allow(Thread).to receive(:new).and_return(thread)
        subject.start
      end

      it 'raises a Pallets::Shutdown error' do
        subject.hard_shutdown
        expect(thread).to have_received(:raise).with(Pallets::Shutdown)
      end
    end

    context 'when not started' do
      it 'returns nil' do
        expect(subject.hard_shutdown).to be_nil
      end
    end
  end

  describe '#id' do
    context 'when started' do
      let(:thread) { instance_spy('Thread', object_id: 'foobar') }

      before do
        allow(Thread).to receive(:new).and_return(thread)
        subject.start
      end

      it 'returns the thread id' do
        expect(subject.id).to eq('foobar')
      end
    end

    context 'when not started' do
      it 'returns nil' do
        expect(subject.id).to be_nil
      end
    end
  end

  describe '#work' do
    let(:backend) { instance_spy('Pallets::Backends::Base', pick_work: job) }
    let(:job) { double }

    before do
      allow(subject).to receive(:loop).and_yield
      allow(subject).to receive(:backend).and_return(backend)
      allow(subject).to receive(:process).with(job)
    end

    it 'tells the backend to pick work' do
      subject.send(:work)
      expect(backend).to have_received(:pick_work)
    end

    context 'with work available' do
      before do
        allow(backend).to receive(:pick_work).and_return(job)
      end

      it 'processes the job' do
        subject.send(:work)
        expect(subject).to have_received(:process).with(job)
      end
    end

    context 'with no work available' do
      before do
        allow(backend).to receive(:pick_work).and_return(nil)
      end

      it 'does not process any job' do
        subject.send(:work)
        expect(subject).not_to have_received(:process)
      end
    end

    context 'when it needs to stop' do
      before do
        allow(subject).to receive(:needs_to_stop?).and_return(true)
      end

      it 'does not process any job' do
        subject.send(:work)
        expect(subject).not_to have_received(:process)
      end

      it 'asks the manager to remove itself' do
        subject.send(:work)
        expect(manager).to have_received(:remove_worker).with(subject)
      end
    end

    context 'when it is forced to stop' do
      before do
        # Simulate a hard shutdown error that occurs while working
        allow(backend).to receive(:pick_work).and_raise(Pallets::Shutdown)
      end

      it 'does not process any job' do
        subject.send(:work)
        expect(subject).not_to have_received(:process)
      end

      it 'asks the manager to remove itself' do
        subject.send(:work)
        expect(manager).to have_received(:remove_worker).with(subject)
      end
    end

    context 'when an unexpected error occurs' do
      before do
        # Simulate an unexpected non-job error that occurs while working
        allow(backend).to receive(:pick_work).and_raise(ArgumentError)
      end

      it 'asks the manager to replace itself' do
        subject.send(:work)
        expect(manager).to have_received(:restart_worker).with(subject)
      end
    end
  end
end
