require 'spec_helper'

describe Pallets::Logger do
  subject { Pallets::Logger.new(output) }

  before do
    subject.formatter = formatter
  end

  let(:output) { StringIO.new }
  let(:formatter) { instance_spy('Logger::Formatter') }

  {
    'debug' => 'DEBUG',
    'info' => 'INFO',
    'warn' => 'WARN',
    'error' => 'ERROR',
    'fatal' => 'FATAL',
    'unknown' => 'ANY'
  }.each do |severity, formatted_severity|
    describe "##{severity}" do
      context 'without metadata' do
        it 'invokes the formatter with the correct arguments' do
          subject.send(severity, 'foo')
          expect(formatter).to have_received(:call).with(
            formatted_severity, a_kind_of(Time), nil, 'foo'
          )
        end
      end

      context 'with metadata' do
        it 'invokes the formatter with the correct arguments' do
          subject.with_metadata(foo: :bar, baz: :qux) do
            subject.send(severity, 'foo')
          end
          expect(formatter).to have_received(:call).with(
            formatted_severity, a_kind_of(Time), ' foo=bar baz=qux', 'foo'
          )
        end
      end
    end
  end

  describe '#with_metadata' do
    it 'yields to the given block' do
      expect { |b| subject.with_metadata(foo: :bar, &b) }.to yield_control
    end

    it 'sets a thread local before yielding to the given block' do
      b = -> { expect(Thread.current[:pallets_log_metadata]).to eq(foo: :bar) }
      subject.with_metadata(foo: :bar, &b)
    end

    it 'removes the thread local after yielding to the given block' do
      subject.with_metadata(foo: :bar) do
        subject.info('foo')
      end
      expect(Thread.current[:pallets_log_metadata]).to be_nil
    end
  end

  context 'using the Pretty formatter' do
    let(:formatter) { Pallets::Logger::Formatters::Pretty.new }

    it 'formats the message correctly' do
      Timecop.freeze do
        subject.with_metadata(foo: :bar) do
          subject.info('foo')
        end
        expect(output.string).to match(
          /#{Time.now.utc.iso8601(4)} pid=\d+ foo=bar INFO: foo\n/
        )
      end
    end
  end
end
