require 'spec_helper'

describe Pallets::Middleware::JobLogger do
  subject { described_class }

  describe '.call' do
    let(:worker) { double(id: 'foo') }
    let(:job) { {} }
    let(:context) { {} }

    it 'yields to the block' do
      expect { |b| subject.call(worker, job, context, &b) }.to yield_control
    end

    context 'when block is successful' do
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
    end
  end
end
