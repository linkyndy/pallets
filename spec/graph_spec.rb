require 'spec_helper'

describe Pallets::Graph do
  describe '#parents' do
    before do
      subject.add(:one,   [])
      subject.add(:two,   [:one])
      subject.add(:three, [:one])
    end

    context 'for root node' do
      it 'returns an empty Array' do
        expect(subject.parents(:one)).to be_an(Array).and be_empty
      end
    end

    context 'for regular node' do
      it 'returns an Array of parent nodes' do
        expect(subject.parents(:two)).to be_an(Array).and contain_exactly(:one)
      end
    end
  end

  describe '#sorted_with_order' do
    let(:graph) do
      Pallets::Graph.new.tap do |g|
        g.add(:one,   [])
        g.add(:two,   [:one])
        g.add(:three, [:one])
        g.add(:four,  [:two])
      end
    end

    it 'returns a properly formatted Array' do
      expect(graph.sorted_with_order).to eq([
        [:one, 0], [:two, 1], [:three, 1], [:four, 3]
      ])
    end

    context 'with a dependency that is not defined' do
      let(:graph) do
        Pallets::Graph.new.tap do |g|
          g.add(:one, [:two])
        end
      end

      it 'raises a KeyError' do
        expect { graph.sorted_with_order }.to raise_error(KeyError)
      end
    end
  end
end
