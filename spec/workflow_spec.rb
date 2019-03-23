require 'spec_helper'

describe Pallets::Workflow do
  let(:backend) { instance_spy('Pallets::Backends::Base') }
  let(:context_class) { class_double('Pallets::Context').as_stubbed_const }
  let(:context) { instance_spy('Pallets::Context', buffer: { foo: :bar }) }
  let(:context_hash) { { foo: :bar } }

  class TestWorkflow < Pallets::Workflow
    task 'Foo'
    task 'Bar' => 'Foo'
    task 'Baz' => 'Foo'
    task 'Qux' => 'Bar'
  end

  class EmptyWorkflow < Pallets::Workflow
  end

  subject { TestWorkflow.new(context_hash) }

  before do
    allow(context_class).to receive(:new).and_return(context)
    allow(context).to receive(:merge!).and_return(context)
    allow(subject).to receive(:backend).and_return(backend)
  end

  it 'initializes a new context and buffers given context hash' do
    subject
    expect(context_class).to have_received(:new)
    expect(context).to have_received(:merge!).with(context_hash)
  end

  describe '#id' do
    it 'returns an ID following a specific pattern' do
      expect(subject.id).to match(/PTWO\h{10}/)
    end
  end

  describe '#run' do
    let(:serializer) { instance_spy('Pallets::Serializers::Base') }

    before do
      allow(Pallets.configuration).to receive(:max_failures).and_return(3)
      allow(subject).to receive(:serializer).and_return(serializer)
      allow(serializer).to receive(:dump).and_return('foobar')
      allow(serializer).to receive(:dump_context).and_return('bazqux')
    end

    context 'with an empty graph' do
      subject { EmptyWorkflow.new(context_hash) }

      it 'raises a WorkflowError' do
        expect do
          subject.run
        end.to raise_error(Pallets::WorkflowError, /no tasks/)
      end
    end

    it 'builds a job for each task and uses the serializer to dump it' do
      Timecop.freeze do
        subject.run
        %w(Foo Bar Baz Qux).each do |task_class|
          expect(serializer).to have_received(:dump).with({
            'wfid' => a_kind_of(String),
            'workflow_class' => 'TestWorkflow',
            'created_at' => Time.now.to_f,
            'task_class' => task_class,
            'max_failures' => 3
          })
        end
      end
    end

    it 'uses the serializer to dump the context buffer' do
      subject.run
      expect(serializer).to have_received(:dump_context).with(foo: :bar)
    end

    it 'tells the backend to run the workflow' do
      Timecop.freeze do
        subject.run
        expect(backend).to have_received(:run_workflow).with(a_kind_of(String), [
          [0, 'foobar'], [1, 'foobar'], [1, 'foobar'], [3, 'foobar']
        ], 'bazqux')
      end
    end
  end
end
