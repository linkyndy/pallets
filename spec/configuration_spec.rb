require 'spec_helper'

describe Pallets::Configuration do
  describe '#pool_size' do
    context 'when explicitly set' do
      before do
        subject.pool_size = 123
      end

      it 'returns the set value' do
        expect(subject.pool_size).to eq(123)
      end
    end

    context 'when not set' do
      it 'returns the concurrency value plus one' do
        expect(subject.pool_size).to eq(subject.concurrency + 1)
      end
    end
  end
end
