require 'spec_helper'

describe Pallets::Scheduler do
  subject { Pallets::Scheduler.new(manager, backend) }

  let(:manager) { instance_spy('Pallets::Manager') }
  let(:backend) { instance_spy('Pallets::Backends::Base') }

  describe '#start' do
    before do
      allow(Pallets.configuration).to receive(:scheduler_polling_interval).and_return(10)
      allow(Thread).to receive(:new).and_yield
      allow(subject).to receive(:work)
      # Do not *actually* sleep
      allow(subject).to receive(:sleep)
    end

    it 'creates a separate thread' do
      subject.start
      expect(Thread).to have_received(:new)
    end

    it 'waits a random number of seconds before it starts working' do
      subject.start
      expect(subject).to have_received(:sleep).with(1).at_most(9).times
    end

    it 'starts working' do
      subject.start
      expect(subject).to have_received(:work)
    end
  end

  describe '#shutdown' do
    it 'signals it needs to stop' do
      expect { subject.shutdown }.to change { subject.needs_to_stop? }.from(false).to(true)
    end

    context 'when started' do
      let(:thread) { instance_spy('Thread') }

      before do
        allow(Thread).to receive(:new).and_return(thread)
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

  describe '#debug' do
    let(:thread) { instance_spy('Thread', backtrace: ['foo'])  }

    before do
      allow(Thread).to receive(:new).and_return(thread)
      subject.start
    end

    it "returns the underlying thread's backtrace" do
      expect(subject.debug).to eq(['foo'])
    end
  end

  describe '#id' do
    context 'when started' do
      let(:thread) { instance_spy('Thread', object_id: 1234) }

      before do
        allow(Thread).to receive(:new).and_return(thread)
        subject.start
      end

      it 'returns an ID following a specific pattern' do
        expect(subject.id).to match(/S\w+/)
      end
    end

    context 'when not started' do
      it 'returns nil' do
        expect(subject.id).to be_nil
      end
    end
  end

  describe '#work' do
    before do
      allow(Pallets.configuration).to receive(:scheduler_polling_interval).and_return(10)
      allow(subject).to receive(:loop).and_yield
      # Do not *actually* sleep
      allow(subject).to receive(:sleep)
    end

    it 'tells the backend to reschedule jobs' do
      Timecop.freeze do
        subject.send(:work)
        expect(backend).to have_received(:reschedule_all).with(Time.now.to_f)
      end
    end

    it 'waits a given number of seconds before it talks to the backend again' do
      subject.send(:work)
      expect(subject).to have_received(:sleep).with(1).exactly(10).times
    end

    context 'when it needs to stop' do
      before do
        allow(subject).to receive(:needs_to_stop?).and_return(true)
      end

      it 'does not tell the backend to reschedule jobs' do
        subject.send(:work)
        expect(backend).not_to have_received(:reschedule_all)
      end

      it 'does not wait for anything' do
        subject.send(:work)
        expect(subject).not_to have_received(:sleep)
      end
    end
  end
end
