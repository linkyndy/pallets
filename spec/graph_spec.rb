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

  describe '#sort_by_dependency_count' do
    before do
      subject.add(:one,   [])
      subject.add(:two,   [:one])
      subject.add(:three, [:one])
      subject.add(:four,  [:two])
    end

    it 'returns a properly formatted Array' do
      expect(subject.sort_by_dependency_count).to eq([
        [0, :one], [1, :two], [1, :three], [3, :four]
      ])
    end
  end
end
