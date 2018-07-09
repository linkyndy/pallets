require 'spec_helper'

describe Pallets::Backends::Redis do
  subject do
    Pallets::Backends::Redis.new(
      namespace: 'test',
      blocking_timeout: 1,
      job_timeout: 10,
      pool_size: 1,
      db: 15
    )
  end

  let(:redis) { ::Redis.new(db: 15) }

  before do
    redis.flushdb
  end

  describe '#pick_work' do
    context 'with work available' do
      before do
        redis.lpush('test:queue', 'foo')
      end

      it 'returns the job' do
        expect(subject.pick_work).to eq('foo')
      end

      it 'pushes the job to the reliability queue' do
        subject.pick_work
        expect(redis.lrem('test:reliability-queue', 0, 'foo')).to eq(1)
      end

      it 'adds the job to the reliability set' do
        Timecop.freeze do
          subject.pick_work
          expect(redis.zscore('test:reliability-set', 'foo')).to eq(Time.now.to_f + 10)
        end
      end
    end

    context 'with no work available' do
      it 'blocks a given number of seconds' do
        start = Time.now
        subject.pick_work
        finish = Time.now
        expect(finish).to be_within(2).of(start)
      end

      it 'returns nil' do
        expect(subject.pick_work).to be_nil
      end

      it 'does not push anything to the reliability queue' do
        subject.pick_work
        expect(redis.lrem('test:reliability-queue', 0, 'foo')).to eq(0)
      end

      it 'does not add anything to the reliability set' do
        subject.pick_work
        expect(redis.zscore('test:reliability-set', 'foo')).to be_nil
      end
    end
  end

  describe '#save_work' do
    before do
      # Set up reliability components
      redis.lpush('test:reliability-queue', 'foo')
      redis.zadd('test:reliability-set', 123, 'foo')

      # Set up jobs sorted set
      redis.zadd('test:workflows:baz', [[1, 'bar'], [2, 'baz'], [5, 'qux']])
    end

    it 'removes the job from the reliability queue' do
      subject.save_work('baz', 'foo')
      # Job is removed, so trying to remove it should return 0
      expect(redis.lrem('test:reliability-queue', 0, 'foo')).to eq(0)
    end

    it 'removes the job from the reliability set' do
      subject.save_work('baz', 'foo')
      expect(redis.zscore('test:reliability-set', 'foo')).to be_nil
    end

    it 'decrements jobs from workflow set' do
      subject.save_work('baz', 'foo')
      expect(redis.zrange('test:workflows:baz', 0, -1, with_scores: true)).to eq([['baz', 1], ['qux', 4]])
    end

    it 'queues jobs that are ready to be processed' do
      subject.save_work('baz', 'foo')
      expect(redis.lrem('test:queue', 0, 'bar')).to eq(1)
    end

    it 'removes jobs that are ready to be processed from workflow set' do
      subject.save_work('baz', 'foo')
      expect(redis.zrange('test:workflows:baz', 0, -1)).not_to include('bar')
    end
  end

  describe '#discard' do
    before do
      # Set up reliability components
      redis.lpush('test:reliability-queue', 'foo')
      redis.zadd('test:reliability-set', 123, 'foo')
    end

    it 'removes the job from the reliability queue' do
      subject.discard('foo')
      # Job is removed, so trying to remove it should return 0
      expect(redis.lrem('test:reliability-queue', 0, 'foo')).to eq(0)
    end

    it 'removes the job from the reliability set' do
      subject.discard('foo')
      expect(redis.zscore('test:reliability-set', 'foo')).to be_nil
    end
  end

  describe '#retry_work' do
    before do
      # Set up reliability components
      redis.lpush('test:reliability-queue', 'foo')
      redis.zadd('test:reliability-set', 123, 'foo')
    end

    it 'removes the job from the reliability queue' do
      subject.retry_work('foonew', 'foo', 1234)
      # Job is removed, so trying to remove it should return 0
      expect(redis.lrem('test:reliability-queue', 0, 'foo')).to eq(0)
    end

    it 'removes the job from the reliability set' do
      subject.retry_work('foonew', 'foo', 1234)
      expect(redis.zscore('test:reliability-set', 'foo')).to be_nil
    end

    it 'adds the new job to the retry set' do
      Timecop.freeze do
        subject.retry_work('foonew', 'foo', 1234)
        expect(redis.zscore('test:retry-queue', 'foonew')).to eq(1234)
      end
    end
  end

  describe '#kill_work' do
    before do
      # Set up reliability components
      redis.lpush('test:reliability-queue', 'foo')
      redis.zadd('test:reliability-set', 123, 'foo')
    end

    it 'removes the job from the reliability queue' do
      subject.kill_work('foonew', 'foo', 1234)
      # Job is removed, so trying to remove it should return 0
      expect(redis.lrem('test:reliability-queue', 0, 'foo')).to eq(0)
    end

    it 'removes the job from the reliability set' do
      subject.kill_work('foonew', 'foo', 1234)
      expect(redis.zscore('test:reliability-set', 'foo')).to be_nil
    end

    it 'adds the new job to the kill set' do
      Timecop.freeze do
        subject.kill_work('foonew', 'foo', 1234)
        expect(redis.zscore('test:failed-queue', 'foonew')).to eq(1234)
      end
    end
  end

  describe '#reschedule_jobs' do
    before do
      # Set up reliability components
      redis.lpush('test:reliability-queue', ['foo', 'bar'])
      redis.zadd('test:reliability-set', [[123, 'foo'], [1000, 'bar']])

      # Set up retry component
      redis.zadd('test:retry-queue', [[123, 'baz'], [1000, 'qux']])
    end

    it 'queues reliability jobs that are ready to be processed' do
      subject.reschedule_jobs(500)
      expect(redis.lrem('test:queue', 0, 'foo')).to eq(1)
    end

    it 'removes jobs that are ready to be processed from the reliability set' do
      subject.reschedule_jobs(500)
      expect(redis.zscore('test:reliability-set', 'foo')).to be_nil
    end

    it 'removes jobs that are ready to be processed from the reliability queue' do
      subject.reschedule_jobs(500)
      # Job is removed, so trying to remove it should return 0
      expect(redis.lrem('test:reliability-queue', 0, 'foo')).to eq(0)
    end

    it 'queues retry jobs that are ready to be processed' do
      subject.reschedule_jobs(500)
      expect(redis.lrem('test:queue', 0, 'baz')).to eq(1)
    end

    it 'removes jobs that are ready to be processed from the retry set' do
      subject.reschedule_jobs(500)
      expect(redis.zscore('test:retry-queue', 'baz')).to be_nil
    end
  end

  describe '#start_workflow' do
    it 'adds jobs to workflow set' do
      subject.start_workflow('baz', [[0, 'foo'], [1, 'bar']])
      expect(redis.zrange('test:workflows:baz', 0, -1, with_scores: true)).to eq([['bar', 1]])
    end

    it 'queues jobs that are ready to be processed' do
      subject.start_workflow('baz', [[0, 'foo'], [1, 'bar']])
      expect(redis.lrem('test:queue', 0, 'foo')).to eq(1)
    end

    it 'removes jobs that are ready to be processed from workflow set' do
      subject.start_workflow('baz', [[0, 'foo'], [1, 'bar']])
      expect(redis.zrange('test:workflows:baz', 0, -1)).not_to include('foo')
    end
  end
end
