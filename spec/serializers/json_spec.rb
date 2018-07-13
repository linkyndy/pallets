require 'spec_helper'

describe Pallets::Serializers::Json do
  let(:json_class) { class_double('JSON').as_stubbed_const }

  before do
    allow(json_class).to receive(:generate)
    allow(json_class).to receive(:parse)
  end

  describe '#dump' do
    it 'generates JSON' do
      subject.dump('foo')
      expect(json_class).to have_received(:generate).with('foo')
    end
  end

  describe '#load' do
    it 'generates JSON' do
      subject.load('foo')
      expect(json_class).to have_received(:parse).with('foo')
    end
  end
end
