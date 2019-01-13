require 'spec_helper'

describe Pallets::Logger do
  subject { Pallets::Logger.new(output, formatter: formatter) }

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
          subject.send(severity, 'foo', { foo: :bar, baz: :qux })
          expect(formatter).to have_received(:call).with(
            formatted_severity, a_kind_of(Time), ' foo=bar baz=qux', 'foo'
          )
        end
      end
    end
  end

  context 'using the Pretty formatter' do
    let(:formatter) { Pallets::Logger::Formatters::Pretty.new }

    it 'formats the message correctly' do
      Timecop.freeze do
        subject.info('foo', { foo: :bar })
        expect(output.string).to match(
          /#{Time.now.utc.iso8601(4)} pid=\d+ foo=bar INFO: foo\n/
        )
      end
    end
  end
end
