require 'spec_helper'

describe Pallets::Graph do
  describe '#parents' do
    before do
      subject.add(:foo, [])
      subject.add(:bar, [:foo])
      subject.add(:baz, [:foo])
    end

    context 'for root node' do
      it 'returns an empty Array' do
        expect(subject.parents(:foo)).to be_an(Array).and be_empty
      end
    end

    context 'for regular node' do
      it 'returns an Array of parent nodes' do
        expect(subject.parents(:bar)).to be_an(Array).and contain_exactly(:foo)
      end
    end
  end

  describe '#empty?' do
    context 'with no nodes added' do
      it 'returns true' do
        expect(subject.empty?).to be(true)
      end
    end

    context 'with nodes added' do
      before do
        subject.add(:foo, [])
      end

      it 'returns false' do
        expect(subject.empty?).to be(false)
      end
    end
  end

  describe '#sorted_with_order' do
    let(:graph) do
      Pallets::Graph.new.tap do |g|
        g.add(:foo, [])
        g.add(:bar, [:foo])
        g.add(:baz, [:foo])
        g.add(:qux, [:bar])
      end
    end

    it 'returns a properly formatted Array' do
      expect(graph.sorted_with_order).to eq([
        [:foo, 0], [:bar, 1], [:baz, 1], [:qux, 3]
      ])
    end

    context 'with a dependency that is not defined' do
      let(:graph) do
        Pallets::Graph.new.tap do |g|
          g.add(:foo, [:bar])
        end
      end

      it 'raises a KeyError' do
        expect { graph.sorted_with_order }.to raise_error(KeyError)
      end
    end
  end
end
