require 'spec_helper'

describe Pallets::Backends::Redis do
  subject do
    Pallets::Backends::Redis.new(
      namespace: 'test',
      blocking_timeout: 1,
      failed_job_lifespan: 100,
      job_timeout: 10,
      pool_size: 1,
      db: 15
    )
  end

  let(:redis) { ::Redis.new(db: 15) }

  before do
    redis.flushdb
  end

  describe '#pick' do
    context 'with work available' do
      before do
        redis.lpush('test:queue', 'foo')
      end

      it 'returns the job' do
        expect(subject.pick).to eq('foo')
      end

      it 'pushes the job to the reliability queue' do
        subject.pick
        expect(redis.lrange('test:reliability-queue', 0, -1)).to eq(['foo'])
      end

      it 'adds the job to the reliability set' do
        Timecop.freeze do
          subject.pick
          expect(redis.zrange('test:reliability-set', 0, -1, with_scores: true)).to eq([['foo', Time.now.to_f + 10]])
        end
      end
    end

    context 'with no work available' do
      it 'blocks a given number of seconds' do
        start = Time.now
        subject.pick
        finish = Time.now
        expect(finish).to be_within(2).of(start)
      end

      it 'returns nil' do
        expect(subject.pick).to be_nil
      end

      it 'does not push anything to the reliability queue' do
        subject.pick
        expect(redis.lrange('test:reliability-queue', 0, -1)).to be_empty
      end

      it 'does not add anything to the reliability set' do
        subject.pick
        expect(redis.zrange('test:reliability-set', 0, -1, with_scores: true)).to be_empty
      end
    end
  end

  describe '#get_context' do
    before do
      # Set up context
      redis.hmset('test:contexts:baz', ['foo', 'bar', 'baz', 'qux'])
    end

    it 'retrieves the context' do
      expect(subject.get_context('baz')).to eq({ 'foo' => 'bar', 'baz' => 'qux' })
    end
  end

  describe '#save' do
    before do
      # Set up reliability components
      redis.lpush('test:reliability-queue', 'foo')
      redis.zadd('test:reliability-set', 123, 'foo')

      # Set up context
      redis.hset('test:contexts:baz', 'foo', 'bar')
    end

    it 'removes the job from the reliability queue' do
      subject.save('baz', 'foo', 'baz' => 'qux')
      expect(redis.lrange('test:reliability-queue', 0, -1)).to be_empty
    end

    it 'removes the job from the reliability set' do
      subject.save('baz', 'foo', 'baz' => 'qux')
      expect(redis.zrange('test:reliability-set', 0, -1, with_scores: true)).to be_empty
    end

    context 'with a non-empty context buffer' do
      it 'adds the context buffer to the context' do
        subject.save('baz', 'foo', 'baz' => 'qux')
        expect(redis.hgetall('test:contexts:baz')).to eq('foo' => 'bar', 'baz' => 'qux')
      end
    end

    context 'with an empty context buffer' do
      it 'does not touch the context' do
        subject.save('baz', 'foo', {})
        expect(redis.hgetall('test:contexts:baz')).to eq('foo' => 'bar')
      end
    end

    context 'with more jobs to queue' do
      before do
        # Set up jobs sorted set
        redis.zadd('test:workflows:baz', [[1, 'bar'], [2, 'baz'], [5, 'qux']])

        # Set up ETA
        redis.set('test:etas:baz', 3)
      end

      it 'decrements and removes jobs with 0 from workflow set' do
        subject.save('baz', 'foo', 'baz' => 'qux')
        expect(redis.zrange('test:workflows:baz', 0, -1, with_scores: true)).to eq([['baz', 1], ['qux', 4]])
      end

      it 'queues jobs that are ready to be processed' do
        subject.save('baz', 'foo', 'baz' => 'qux')
        expect(redis.lrange('test:queue', 0, -1)).to eq(['bar'])
      end

      it 'decrements the ETA' do
        subject.save('baz', 'foo', 'baz' => 'qux')
        expect(redis.get('test:etas:baz')).to eq('2')
      end
    end

    context 'with no more jobs to queue' do
      before do
        # Set up ETA
        redis.set('test:etas:baz', 1)
      end

      it 'clears the context' do
        subject.save('baz', 'foo', 'baz' => 'qux')
        expect(redis.exists('test:contexts:baz')).to be(false)
      end

      it 'clears the ETA' do
        subject.save('baz', 'foo', 'baz' => 'qux')
        expect(redis.exists('test:etas:baz')).to be(false)
      end
    end
  end

  describe '#retry' do
    before do
      # Set up reliability components
      redis.lpush('test:reliability-queue', 'foo')
      redis.zadd('test:reliability-set', 123, 'foo')
    end

    it 'removes the job from the reliability queue' do
      subject.retry('foonew', 'foo', 1234)
      expect(redis.lrange('test:reliability-queue', 0, -1)).to be_empty
    end

    it 'removes the job from the reliability set' do
      subject.retry('foonew', 'foo', 1234)
      expect(redis.zrange('test:reliability-set', 0, -1, with_scores: true)).to be_empty
    end

    it 'adds the new job to the retry set' do
      Timecop.freeze do
        subject.retry('foonew', 'foo', 1234)
        expect(redis.zrange('test:retry-set', 0, -1, with_scores: true)).to eq([['foonew', 1234]])
      end
    end
  end

  describe '#give_up' do
    before do
      # Set up reliability components
      redis.lpush('test:reliability-queue', 'foo')
      redis.zadd('test:reliability-set', 123, 'foo')
    end

    it 'removes the job from the reliability queue' do
      subject.give_up('foonew', 'foo')
      expect(redis.lrange('test:reliability-queue', 0, -1)).to be_empty
    end

    it 'removes the job from the reliability set' do
      subject.give_up('foonew', 'foo')
      expect(redis.zrange('test:reliability-set', 0, -1, with_scores: true)).to be_empty
    end

    it 'adds the new job to the given up set' do
      Timecop.freeze do
        subject.give_up('foonew', 'foo')
        expect(redis.zrange('test:given-up-set', 0, -1, with_scores: true)).to eq([['foonew', Time.now.to_f]])
      end
    end

    context 'with a given up job that failed a long time ago' do
      before do
        redis.zadd('test:given-up-set', 1234, 'bar')
      end

      it 'removes the given up job from the given up set' do
        Timecop.freeze do
          subject.give_up('foonew', 'foo')
          expect(redis.zrange('test:given-up-set', 0, -1)).not_to include('bar')
        end
      end
    end
  end

  describe '#reschedule_all' do
    before do
      # Set up reliability components
      redis.lpush('test:reliability-queue', ['foo', 'bar'])
      redis.zadd('test:reliability-set', [[123, 'foo'], [1000, 'bar']])

      # Set up retry component
      redis.zadd('test:retry-set', [[123, 'baz'], [1000, 'qux']])
    end

    it 'queues reliability and retry jobs that are ready to be processed' do
      subject.reschedule_all(500)
      expect(redis.lrange('test:queue', 0, -1)).to contain_exactly('foo', 'baz')
    end

    it 'removes jobs that are ready to be processed from the reliability set' do
      subject.reschedule_all(500)
      expect(redis.zrange('test:reliability-set', 0, -1, with_scores: true)).to eq([['bar', 1000]])
    end

    it 'removes jobs that are ready to be processed from the reliability queue' do
      subject.reschedule_all(500)
      expect(redis.lrange('test:reliability-queue', 0, -1)).to eq(['bar'])
    end

    it 'removes jobs that are ready to be processed from the retry set' do
      subject.reschedule_all(500)
      expect(redis.zrange('test:retry-set', 0, -1, with_scores: true)).to eq([['qux', 1000]])
    end
  end

  describe '#run_workflow' do
    it 'sets the ETA' do
      subject.run_workflow('baz', [[0, 'foo'], [1, 'bar']], 'foo' => 'bar')
      expect(redis.get('test:etas:baz')).to eq('2')
    end

    it 'adds pending jobs to workflow set' do
      subject.run_workflow('baz', [[0, 'foo'], [1, 'bar']], 'foo' => 'bar')
      expect(redis.zrange('test:workflows:baz', 0, -1, with_scores: true)).to eq([['bar', 1]])
    end

    it 'queues jobs that are ready to be processed' do
      subject.run_workflow('baz', [[0, 'foo'], [1, 'bar']], 'foo' => 'bar')
      expect(redis.lrange('test:queue', 0, -1)).to eq(['foo'])
    end

    context 'with a non-empty context' do
      it 'sets the context' do
        subject.run_workflow('baz', [[0, 'foo'], [1, 'bar']], 'foo' => 'bar')
        expect(redis.hgetall('test:contexts:baz')).to eq('foo' => 'bar')
      end
    end

    context 'with an empty context' do
      it 'does not set the context' do
        subject.run_workflow('baz', [[0, 'foo'], [1, 'bar']], {})
        expect(redis.exists('test:contexts:baz')).to be(false)
      end
    end
  end
end
