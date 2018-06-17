require 'spec_helper'

describe Pallets::Scheduler do
  subject { Pallets::Scheduler.new(manager) }

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

  describe '#shutdown' do
    let(:thread) { instance_spy('Thread') }

    before do
      allow(Thread).to receive(:new).and_return(thread)
    end

    context 'when started' do
      before do
        subject.start
      end

      it 'waits for the thread to finish' do
        subject.shutdown
        expect(thread).to have_received(:join)
      end
    end

    context 'when not started' do
      it 'returns nil' do
        expect(subject.shutdown).to be_nil
      end
    end
  end
end
