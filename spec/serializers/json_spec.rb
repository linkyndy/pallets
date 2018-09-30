require 'spec_helper'

describe Pallets::Serializers::Json do
  let(:json_class) { class_double('JSON').as_stubbed_const }

  it 'properly serializes and deserializes data' do
    expect(subject.load(subject.dump('foo'))).to eq('foo')
  end

  describe '#dump' do
    before do
      allow(json_class).to receive(:generate)
    end

    it 'generates JSON' do
      subject.dump('foo')
      expect(json_class).to have_received(:generate).with('foo')
    end
  end

  describe '#load' do
    before do
      allow(json_class).to receive(:parse)
    end

    it 'parses JSON' do
      subject.load('foo')
      expect(json_class).to have_received(:parse).with('foo')
    end
  end
end
