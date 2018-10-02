require 'spec_helper'

describe Pallets::Serializers::Msgpack do
  let(:msgpack_class) { class_double('MessagePack').as_stubbed_const }

  it 'properly serializes and deserializes data' do
    expect(subject.load(subject.dump('foo'))).to eq('foo')
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
end
