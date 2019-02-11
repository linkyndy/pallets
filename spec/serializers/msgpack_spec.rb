require 'spec_helper'

describe Pallets::Serializers::Msgpack do
  let(:msgpack_class) { class_double('MessagePack').as_stubbed_const }

  it 'properly serializes and deserializes data' do
    expect(subject.load(subject.dump('foo'))).to eq('foo')
  end

  it 'properly serializes and deserializes context data' do
    expect(subject.load_context(subject.dump_context('foo' => 'bar'))).to eq('foo' => 'bar')
  end

  describe '#dump' do
    before do
      allow(msgpack_class).to receive(:pack)
    end

    it 'packs data' do
      subject.dump('foo')
      expect(msgpack_class).to have_received(:pack).with('foo')
    end
  end

  describe '#load' do
    before do
      allow(msgpack_class).to receive(:unpack)
    end

    it 'unpacks data' do
      subject.load('foo')
      expect(msgpack_class).to have_received(:unpack).with('foo')
    end
  end

  describe '#dump_context' do
    before do
      allow(msgpack_class).to receive(:pack)
    end

    it 'packs hash values' do
      subject.dump_context('foo' => 'bar')
      expect(msgpack_class).to have_received(:pack).with('bar')
    end
  end

  describe '#load_context' do
    before do
      allow(msgpack_class).to receive(:unpack)
    end

    it 'unpacks hash values' do
      subject.load_context('foo' => 'bar')
      expect(msgpack_class).to have_received(:unpack).with('bar')
    end
  end
end
