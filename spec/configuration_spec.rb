require 'spec_helper'

describe Pallets::Configuration do
  describe '#logger' do
    context 'when explicitly set' do
      let(:logger) { Logger.new(STDOUT) }
      
      before do
        subject.logger = logger
      end

      it 'returns the set logger' do
        expect(subject.logger).to be(logger)
      end
    end

    context 'when not set' do
      it 'returns the default logger' do
        expect(subject.logger).to be_a(Pallets::Logger)
      end
    end
  end

  describe '#pool_size' do
    before do
      subject.concurrency = 12
    end

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
        expect(subject.pool_size).to eq(13)
      end
    end
  end

  describe '#middleware' do
    it 'is a Pallets::Middleware::Stack' do
      expect(subject.middleware).to be_a(Pallets::Middleware::Stack)
    end
  end
end
