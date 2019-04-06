require 'spec_helper'

describe Pallets::Graph do
  describe '#parents' do
    before do
      subject.add('Foo', [])
      subject.add('Bar', ['Foo'])
      subject.add('Baz', ['Foo'])
    end

    context 'for root node' do
      it 'returns an empty Array' do
        expect(subject.parents('Foo')).to be_an(Array).and be_empty
      end
    end

    context 'for regular node' do
      it 'returns an Array of parent nodes' do
        expect(subject.parents('Bar')).to be_an(Array).and contain_exactly('Foo')
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
        subject.add('Foo', [])
      end

      it 'returns false' do
        expect(subject.empty?).to be(false)
      end
    end
  end

  describe '#sorted_with_order' do
    let(:graph) do
      Pallets::Graph.new.tap do |g|
        g.add('Foo', [])
        g.add('Bar', ['Foo'])
        g.add('Baz', ['Foo'])
        g.add('Qux', ['Bar'])
      end
    end

    it 'returns a properly formatted Array' do
      expect(graph.sorted_with_order).to eq([
        ['Foo', 0], ['Bar', 1], ['Baz', 1], ['Qux', 3]
      ])
    end

    context 'with a dependency that is not defined' do
      let(:graph) do
        Pallets::Graph.new.tap do |g|
          g.add('Foo', ['Bar'])
        end
      end

      it 'raises a WorkflowError' do
        expect { graph.sorted_with_order }.to raise_error(Pallets::WorkflowError)
      end
    end
  end
end
