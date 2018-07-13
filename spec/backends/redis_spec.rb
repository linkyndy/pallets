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

  describe '#save' do
    before do
      # Set up reliability components
      redis.lpush('test:reliability-queue', 'foo')
      redis.zadd('test:reliability-set', 123, 'foo')

      # Set up jobs sorted set
      redis.zadd('test:workflows:baz', [[1, 'bar'], [2, 'baz'], [5, 'qux']])
    end

    it 'removes the job from the reliability queue' do
      subject.save('baz', 'foo')
      expect(redis.lrange('test:reliability-queue', 0, -1)).to be_empty
    end

    it 'removes the job from the reliability set' do
      subject.save('baz', 'foo')
      expect(redis.zrange('test:reliability-set', 0, -1, with_scores: true)).to be_empty
    end

    it 'decrements and removed jobs with 0 from workflow set' do
      subject.save('baz', 'foo')
      expect(redis.zrange('test:workflows:baz', 0, -1, with_scores: true)).to eq([['baz', 1], ['qux', 4]])
    end

    it 'queues jobs that are ready to be processed' do
      subject.save('baz', 'foo')
      expect(redis.lrange('test:queue', 0, -1)).to eq(['bar'])
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
      expect(redis.lrange('test:reliability-queue', 0, -1)).to be_empty
    end

    it 'removes the job from the reliability set' do
      subject.discard('foo')
      expect(redis.zrange('test:reliability-set', 0, -1, with_scores: true)).to be_empty
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
        expect(redis.zrange('test:retry-queue', 0, -1, with_scores: true)).to eq([['foonew', 1234]])
      end
    end
  end

  describe '#kill' do
    before do
      # Set up reliability components
      redis.lpush('test:reliability-queue', 'foo')
      redis.zadd('test:reliability-set', 123, 'foo')
    end

    it 'removes the job from the reliability queue' do
      subject.kill('foonew', 'foo', 1234)
      expect(redis.lrange('test:reliability-queue', 0, -1)).to be_empty
    end

    it 'removes the job from the reliability set' do
      subject.kill('foonew', 'foo', 1234)
      expect(redis.zrange('test:reliability-set', 0, -1, with_scores: true)).to be_empty
    end

    it 'adds the new job to the kill set' do
      Timecop.freeze do
        subject.kill('foonew', 'foo', 1234)
        expect(redis.zrange('test:failed-queue', 0, -1, with_scores: true)).to eq([['foonew', 1234]])
      end
    end
  end

  describe '#reschedule' do
    before do
      # Set up reliability components
      redis.lpush('test:reliability-queue', ['foo', 'bar'])
      redis.zadd('test:reliability-set', [[123, 'foo'], [1000, 'bar']])

      # Set up retry component
      redis.zadd('test:retry-queue', [[123, 'baz'], [1000, 'qux']])
    end

    it 'queues reliability and retry jobs that are ready to be processed' do
      subject.reschedule(500)
      expect(redis.lrange('test:queue', 0, -1)).to contain_exactly('foo', 'baz')
    end

    it 'removes jobs that are ready to be processed from the reliability set' do
      subject.reschedule(500)
      expect(redis.zrange('test:reliability-set', 0, -1, with_scores: true)).to eq([['bar', 1000]])
    end

    it 'removes jobs that are ready to be processed from the reliability queue' do
      subject.reschedule(500)
      expect(redis.lrange('test:reliability-queue', 0, -1)).to eq(['bar'])
    end

    it 'removes jobs that are ready to be processed from the retry set' do
      subject.reschedule(500)
      expect(redis.zrange('test:retry-queue', 0, -1, with_scores: true)).to eq([['qux', 1000]])
    end
  end

  describe '#start_workflow' do
    it 'adds pending jobs to workflow set' do
      subject.start_workflow('baz', [[0, 'foo'], [1, 'bar']])
      expect(redis.zrange('test:workflows:baz', 0, -1, with_scores: true)).to eq([['bar', 1]])
    end

    it 'queues jobs that are ready to be processed' do
      subject.start_workflow('baz', [[0, 'foo'], [1, 'bar']])
      expect(redis.lrange('test:queue', 0, -1)).to eq(['foo'])
    end
  end
end
