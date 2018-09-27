require 'spec_helper'

describe Pallets::Pool do
  it 'initializes the correct number of items' do
    pool = Pallets::Pool.new(10) { :foo }
    expect(pool.size).to eq(10)
  end

  it 'raises an error if no block is provided' do
    expect { Pallets::Pool.new(10) }.to raise_error(ArgumentError)
  end

  describe '#execute' do
    subject { Pallets::Pool.new(1) { :foo } }

    it 'raises an error if no block is provided' do
      expect { subject.execute }.to raise_error(ArgumentError)
    end

    it 'yields an item to the provided block' do
      expect do |b|
        subject.execute(&b)
      end.to yield_with_args(:foo)
    end

    it 'puts back the item' do
      subject.execute { }
      expect(subject.size).to eq(1)
    end
  end
end
