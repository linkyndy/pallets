require 'spec_helper'

describe Pallets::Workflow do
  let(:backend) { instance_spy('Pallets::Backends::Base') }
  let(:context) { { foo: :bar } }

  class TestWorkflow < Pallets::Workflow
    task :one
    task :two => :one
    task :three => :one
    task :four => :two
  end

  subject { TestWorkflow.new(context) }

  describe '#id' do
    it 'returns an ID following a specific pattern' do
      expect(subject.id).to match(/PTWO\h{10}/)
    end
  end

  describe '#run' do
    let(:serializer) { instance_spy('Pallets::Serializers::Base', dump: 'foobar') }

    before do
      allow(Pallets.configuration).to receive(:max_failures).and_return(3)
      allow(subject).to receive(:backend).and_return(backend)
      allow(subject).to receive(:serializer).and_return(serializer)
    end

    it 'builds a job for each task and uses the serializer to dump it' do
      Timecop.freeze do
        subject.run
        %w(One Two Three Four).each do |task_class_name|
          expect(serializer).to have_received(:dump).with({
            'workflow_id' => a_kind_of(String),
            'context' => { foo: :bar },
            'created_at' => Time.now.to_f,
            'class_name' => task_class_name,
            'max_failures' => 3
          })
        end
      end
    end

    it 'tells the backend to run the workflow' do
      Timecop.freeze do
        subject.run
        expect(backend).to have_received(:run_workflow).with(a_kind_of(String), [
          [0, 'foobar'], [1, 'foobar'], [1, 'foobar'], [3, 'foobar']
        ])
      end
    end
  end
end
