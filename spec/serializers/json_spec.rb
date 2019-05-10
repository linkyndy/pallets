require 'spec_helper'

describe Pallets::Serializers::Json do
  let(:json_class) { class_double('JSON').as_stubbed_const }

  it 'properly serializes and deserializes data' do
    expect(subject.load(subject.dump('foo' => 'bar'))).to eq('foo' => 'bar')
  end

  it 'properly serializes and deserializes context data' do
    expect(subject.load_context(subject.dump_context('foo' => 'bar'))).to eq('foo' => 'bar')
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

  describe '#dump_context' do
    before do
      allow(json_class).to receive(:generate)
    end

    it 'generates JSON for hash values' do
      subject.dump_context('foo' => 'bar')
      expect(json_class).to have_received(:generate).with('bar')
    end
  end

  describe '#load' do
    before do
      allow(json_class).to receive(:parse)
    end

    it 'parses JSON for hash values' do
      subject.load_context('foo' => 'bar')
      expect(json_class).to have_received(:parse).with('bar')
    end
  end
end
