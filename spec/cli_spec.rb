require 'spec_helper'

describe Pallets::CLI do
  context 'with --backend provided' do
    before do
      stub_const('ARGV', ['--backend=foo'])
    end

    it 'sets the given backend' do
      subject
      expect(Pallets.configuration.backend).to eq('foo')
    end
  end

  context 'with --namespace provided' do
    before do
      stub_const('ARGV', ['--namespace=foo'])
    end

    it 'sets the given namespace' do
      subject
      expect(Pallets.configuration.namespace).to eq('foo')
    end
  end

  context 'with --pool-size provided' do
    before do
      stub_const('ARGV', ['--pool-size=123'])
    end

    it 'sets the given pool size' do
      subject
      expect(Pallets.configuration.pool_size).to eq(123)
    end
  end

  context 'with --quiet provided' do
    before do
      stub_const('ARGV', ['--quiet'])
    end

    it 'sets the ERROR logging level' do
      subject
      expect(Pallets.logger.level).to eq(Logger::ERROR)
    end
  end

  context 'with --require provided' do
    context 'and a valid path' do
      before do
        stub_const('ARGV', ['--require=spec_helper'])
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'and a path that does not exist' do
      before do
        stub_const('ARGV', ['--require=foo'])
      end

      it 'raises a LoadError' do
        expect { subject }.to raise_error(LoadError)
      end
    end
  end

  context 'with --serializer provided' do
    before do
      stub_const('ARGV', ['--serializer=foo'])
    end

    it 'sets the given serializer' do
      subject
      expect(Pallets.configuration.serializer).to eq('foo')
    end
  end

  context 'with --blocking-timeout provided' do
    before do
      stub_const('ARGV', ['--blocking-timeout=123'])
    end

    it 'sets the given blocking timeout' do
      subject
      expect(Pallets.configuration.blocking_timeout).to eq(123)
    end
  end

  context 'with --verbose provided' do
    before do
      stub_const('ARGV', ['--verbose'])
    end

    it 'sets the DEBUG logging level' do
      subject
      expect(Pallets.logger.level).to eq(Logger::DEBUG)
    end
  end

  describe '#run' do
    let(:manager_class) { class_double('Pallets::Manager').as_stubbed_const }
    let(:manager) { instance_spy('Pallets::Manager') }
    let(:queue_class) { class_double('Queue').as_stubbed_const }
    let(:queue) { instance_spy('Queue') }

    before do
      allow(manager_class).to receive(:new).and_return(manager)
      allow(queue_class).to receive(:new).and_return(queue)
      allow(subject).to receive(:loop).and_yield
    end

    it 'starts the manager' do
      subject.run
      expect(manager).to have_received(:start)
    end

    context 'with an INT signal being sent' do
      before do
        allow(queue).to receive(:pop).and_return('INT')
      end

      it 'shuts down the manager' do
        subject.run
        expect(manager).to have_received(:shutdown)
      end
    end
  end
end
