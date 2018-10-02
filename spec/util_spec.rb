require 'spec_helper'

describe Pallets::Util do
  subject { described_class }

  describe '.camelize' do
    {
      ''            => '',
      'foo'         => 'Foo',
      'Foo'         => 'Foo',
      'foo_bar'     => 'FooBar',
      'Foo_bar'     => 'FooBar',
      'foo_bar_baz' => 'FooBarBaz',
      'FooBar'      => 'FooBar',
      :foo_bar      => 'FooBar'
    }.each do |input, output|
      it "correctly camelizes #{input}" do
        expect(subject.camelize(input)).to eq(output)
      end
    end
  end

  describe '.constantize' do
    context 'with valid input' do
      {
        'Pallets'                     => Pallets,
        '::Pallets'                   => ::Pallets,
        'Pallets::Util'               => Pallets::Util,
        'Pallets::Serializers::Base'  => Pallets::Serializers::Base
      }.each do |input, output|
        it "correctly constantizes #{input}" do
          expect(subject.constantize(input)).to be(output)
        end
      end
    end

    context 'with invalid input' do
      [
        '',
        'Inexisting',
        '::Inexisting',
        'Pallets::Inexisting',
        '::Pallets::Inexisting'
      ].each do |input|
        it "raises a NameError for #{input}" do
          expect { subject.constantize(input) }.to raise_error(NameError)
        end
      end
    end
  end
end
