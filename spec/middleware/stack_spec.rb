require 'spec_helper'
require 'pry-byebug'

describe Pallets::Middleware::Stack do
  it 'is an Array' do
    expect(subject).to be_an(Array)
  end

  describe '#invoke' do
    # Records all events in the order they occur
    let(:rec) { [] }
    let(:block) { -> { rec << :block } }

    context 'with no middleware' do
      it 'calls the block' do
        subject.invoke(:foo, &block)
        expect(rec).to eq([:block])
      end
    end

    context 'with middleware' do
      let(:first_middleware) do
        ->(arg, &b) { rec << [arg, :before_first]; b.call; rec << [arg, :after_first] }
      end
      let(:second_middleware) do
        ->(arg, &b) { rec << [arg, :before_second]; b.call; rec << [arg, :after_second] }
      end

      before do
        # Add middleware to stack
        subject << first_middleware << second_middleware
      end

      it 'calls the middleware in order with the correct arguments, then the block' do
        subject.invoke(:foo, &block)
        expect(rec).to eq([
          [:foo, :before_first],
          [:foo, :before_second],
          :block,
          [:foo, :after_second],
          [:foo, :after_first]
        ])
      end
    end
  end
end
