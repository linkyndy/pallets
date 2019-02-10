require 'spec_helper'

describe Pallets::Context do
  it 'is a Hash' do
    expect(subject).to be_a(Hash)
  end

  describe '#[]=' do
    it 'buffers the given value' do
      subject['foo'] = 'bar'
      expect(subject.buffer).to match('foo' => 'bar')
    end

    it 'does not alter the Hash interface' do
      subject['foo'] = 'bar'
      expect(subject['foo']).to eq('bar')
    end
  end

  describe '#merge!' do
    it 'buffers the given hash' do
      subject.merge!('foo' => 'bar')
      expect(subject.buffer).to match('foo' => 'bar')
    end

    it 'does not alter the Hash interface' do
      subject.merge!('foo' => 'bar')
      expect(subject['foo']).to eq('bar')
    end
  end

  describe '#buffer' do
    context 'when no context has been set' do
      it 'returns an empty Hash' do
        expect(subject.buffer).to be_a(Hash).and be_empty
      end
    end

    context 'when context has been set' do
      before do
        subject['foo'] = 'bar'
      end

      it 'returns a Hash' do
        expect(subject.buffer).to match('foo' => 'bar')
      end
    end
  end
end
