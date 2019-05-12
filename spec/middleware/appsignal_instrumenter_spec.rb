require 'spec_helper'

describe Pallets::Middleware::AppsignalInstrumenter do
  subject { described_class }

  describe '.call' do
    let(:worker) { double(id: 'foo') }
    let(:job) do
      {
        'task_class' => 'Foo',
        'workflow_class' => 'Bar'
      }
    end
    let(:context) do
      { 'foo' => 'bar' }
    end

    let(:transaction) { instance_spy('Appsignal::Transaction') }

    before do
      allow(Appsignal::Transaction).to receive(:create).and_return(transaction)
      allow(Appsignal).to receive(:config).and_return(filter_parameters: [])
    end

    it 'yields to the block' do
      expect { |b| subject.call(worker, job, context, &b) }.to yield_control
    end

    context 'when block is successful' do
      it 'instruments job execution with Appsignal' do
        expect(Appsignal::Transaction).to receive(:create)
        expect(Appsignal).to receive(:instrument).with('perform_job.pallets').and_call_original
        expect(transaction).to receive(:set_action_if_nil).with('Foo#run (Bar)')
        expect(transaction).to receive(:params=).with('foo' => 'bar')
        expect(transaction).to receive(:set_metadata).with('task_class', 'Foo')
        expect(transaction).to receive(:set_metadata).with('workflow_class', 'Bar')
        expect(transaction).to receive(:set_http_or_background_queue_start)
        expect(Appsignal::Transaction).to receive(:complete_current!)
        expect(Appsignal).to receive(:increment_counter).with('pallets_job_count', 1, status: :successful)

        subject.call(worker, job, context) { :foo }
      end

      it 'returns the result of the block' do
        expect(subject.call(worker, job, context) { :foo }).to eq(:foo)
      end
    end

    context 'when block raises an error' do
      it 'reraises the error' do
        expect do
          subject.call(worker, job, context) { raise ArgumentError }
        end.to raise_error(ArgumentError)
      end

      it 'instruments job execution with Appsignal' do
        expect(Appsignal::Transaction).to receive(:create)
        expect(Appsignal).to receive(:instrument).with('perform_job.pallets').and_call_original
        expect(transaction).to receive(:set_error).with(ArgumentError)
        expect(transaction).to receive(:set_action_if_nil).with('Foo#run (Bar)')
        expect(transaction).to receive(:params=).with('foo' => 'bar')
        expect(transaction).to receive(:set_metadata).with('task_class', 'Foo')
        expect(transaction).to receive(:set_metadata).with('workflow_class', 'Bar')
        expect(transaction).to receive(:set_http_or_background_queue_start)
        expect(Appsignal::Transaction).to receive(:complete_current!)
        expect(Appsignal).to receive(:increment_counter).with('pallets_job_count', 1, status: :failed)

        expect do
          subject.call(worker, job, context) { raise ArgumentError }
        end.to raise_error(ArgumentError)
      end
    end
  end
end
