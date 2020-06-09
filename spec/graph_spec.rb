require 'spec_helper'

describe Pallets::Graph do
  describe '#add' do
    it 'adds node and its dependencies' do
      subject.add('Foo', ['Bar'])
      expect(subject.send(:nodes)).to match('Foo' => ['Bar'])
    end

    context 'with a node that already exists' do
      before do
        subject.add('Foo', [])
      end

      it 'raises a WorkflowError' do
        expect { subject.add('Foo', ['Bar']) }.to raise_error(Pallets::WorkflowError)
      end
    end
  end

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

  describe '#each' do
    let(:graph) do
      Pallets::Graph.new.tap do |g|
        g.add('Foo', [])
        g.add('Bar', ['Foo'])
        g.add('Baz', ['Foo'])
        g.add('Qux', ['Bar'])
      end
    end

    context 'with a given block' do
      it 'yields the correct elements' do
        expect { |b| graph.each(&b) }.to yield_successive_args(
          ['Foo', []], ['Bar', ['Foo']], ['Baz', ['Foo']], ['Qux', ['Bar']]
        )
      end
    end

    context 'without a block' do
      it 'returns an Enumerator that yields the correct elements' do
        expect(graph.each).to be_an(Enumerator)
        expect(graph.each.to_a).to eq([
          ['Foo', []], ['Bar', ['Foo']], ['Baz', ['Foo']], ['Qux', ['Bar']]
        ])
      end
    end

    context 'with a dependency that is not defined' do
      let(:graph) do
        Pallets::Graph.new.tap do |g|
          g.add('Foo', ['Bar'])
        end
      end

      it 'raises a WorkflowError' do
        expect { graph.each.to_a }.to raise_error(Pallets::WorkflowError)
      end
    end
  end
end
