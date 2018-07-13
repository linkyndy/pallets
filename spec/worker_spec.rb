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
    let(:backend) { instance_spy('Pallets::Backends::Base', pick: job) }
    let(:job) { double }

    before do
      allow(subject).to receive(:loop).and_yield
      allow(subject).to receive(:backend).and_return(backend)
      allow(subject).to receive(:process).with(job)
    end

    it 'tells the backend to pick work' do
      subject.send(:work)
      expect(backend).to have_received(:pick)
    end

    context 'with work available' do
      before do
        allow(backend).to receive(:pick).and_return(job)
      end

      it 'processes the job' do
        subject.send(:work)
        expect(subject).to have_received(:process).with(job)
      end
    end

    context 'with no work available' do
      before do
        allow(backend).to receive(:pick).and_return(nil)
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
        allow(backend).to receive(:pick).and_raise(Pallets::Shutdown)
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
        allow(backend).to receive(:pick).and_raise(ArgumentError)
      end

      it 'asks the manager to replace itself' do
        subject.send(:work)
        expect(manager).to have_received(:replace_worker).with(subject)
      end
    end
  end

  describe '#process' do
    let(:backend) { instance_spy('Pallets::Backends::Base') }
    let(:serializer) { instance_spy('Pallets::Serializers::Base', load: job_hash) }
    let(:job) { double }
    let(:job_hash) do
      {
        'class_name' => 'Foo',
        'context' => { bar: :baz },
        'wfid' => 'qux'
      }
    end
    let(:task_class) { class_double('Foo').as_stubbed_const }
    let(:task) { instance_spy('Foo') }

    class Foo < Pallets::Task
      def run
      end
    end

    before do
      allow(subject).to receive(:backend).and_return(backend)
      allow(subject).to receive(:serializer).and_return(serializer)
      allow(task_class).to receive(:new).and_return(task)
      allow(subject).to receive(:handle_job_error)
    end

    it 'uses the serializer to load the job' do
      subject.send(:process, job)
      expect(serializer).to have_received(:load).with(job)
    end

    context 'when an unexpected error occurs while loading the job' do
      before do
        # Simulate an unexpected error that occurs while loading the job
        allow(serializer).to receive(:load).and_raise(ArgumentError)
      end

      it 'tells the backend to discard the job' do
        subject.send(:process, job)
        expect(backend).to have_received(:discard).with(job)
      end

      it 'does not instantiate the task' do
        subject.send(:process, job)
        expect(task_class).not_to have_received(:new)
      end

      it 'runs the task' do
        subject.send(:process, job)
        expect(task).not_to have_received(:run)
      end

      it 'does not tell the backend to save the job' do
        subject.send(:process, job)
        expect(backend).not_to have_received(:save)
      end
    end

    it 'instantiates the correct task' do
      subject.send(:process, job)
      expect(task_class).to have_received(:new).with(bar: :baz)
    end

    it 'runs the task' do
      subject.send(:process, job)
      expect(task).to have_received(:run)
    end

    context 'when an unexpected error occurs while running the task' do
      before do
        # Simulate an unexpected job error that occurs while running the task
        allow(task).to receive(:run).and_raise(ArgumentError)
      end

      it 'calls the error handler' do
        subject.send(:process, job)
        expect(subject).to have_received(:handle_job_error).with(a_kind_of(ArgumentError), job, job_hash)
      end
    end

    context 'when the task is run successfully' do
      it 'tells the backend to save the job' do
        subject.send(:process, job)
        expect(backend).to have_received(:save).with('qux', job)
      end
    end
  end

  describe '#handle_job_error' do
    let(:backend) { instance_spy('Pallets::Backends::Base') }
    let(:serializer) { instance_spy('Pallets::Serializers::Base', dump: 'foobar') }
    let(:ex) { ArgumentError.new('foo') }
    let(:job) { double }
    let(:job_hash) do
      {
        'class_name' => 'Foo',
        'context' => { bar: :baz },
        'wfid' => 'qux'
      }
    end

    before do
      allow(subject).to receive(:backend).and_return(backend)
      allow(subject).to receive(:serializer).and_return(serializer)
    end

    context 'with no previous failures' do
      it 'builds a new job and uses the serializer to dump it' do
        Timecop.freeze do
          subject.send(:handle_job_error, ex, job, job_hash)
          expect(serializer).to have_received(:dump).with(job_hash.merge(
            'failures' => 1,
            'failed_at' => Time.now.to_f,
            'error_class' => 'ArgumentError',
            'error_message' => 'foo'
          ))
        end
      end
    end

    context 'with previous failures' do
      let(:job_hash) do
        {
          'class_name' => 'Foo',
          'context' => { bar: :baz },
          'wfid' => 'qux',
          'failures' => 1,
          'failed_at' => Time.now.to_f,
          'error_class' => 'KeyError',
          'error_message' => 'bar'
        }
      end

      it 'builds a new job and uses the serializer to dump it' do
        Timecop.freeze do
          subject.send(:handle_job_error, ex, job, job_hash)
          expect(serializer).to have_received(:dump).with(job_hash.merge(
            'failures' => 2,
            'failed_at' => Time.now.to_f,
            'error_class' => 'ArgumentError',
            'error_message' => 'foo'
          ))
        end
      end
    end

    context 'with the number of failures within the threshold' do
      it 'tells the backend to retry the job' do
        Timecop.freeze do
          subject.send(:handle_job_error, ex, job, job_hash)
          expect(backend).to have_received(:retry).with(
            'foobar', job, a_value > Time.now.to_f
          )
        end
      end
    end

    context 'with the number of failures exceeding the threshold' do
      let(:job_hash) do
        {
          'class_name' => 'Foo',
          'context' => { bar: :baz },
          'wfid' => 'qux',
          'failures' => 15,
          'failed_at' => Time.now.to_f,
          'error_class' => 'KeyError',
          'error_message' => 'bar'
        }
      end

      it 'tells the backend to kill the job' do
        Timecop.freeze do
          subject.send(:handle_job_error, ex, job, job_hash)
          expect(backend).to have_received(:kill).with(
            'foobar', job, Time.now.to_f
          )
        end
      end
    end
  end
end
