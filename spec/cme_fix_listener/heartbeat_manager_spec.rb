require 'spec_helper'
require 'redis_test_helpers'

describe CmeFixListener::HeartbeatManager do
  include RedisTestHelpers

  let(:klass) { described_class }
  let(:account) { { 'id' => 123 } }

  describe '.add_heartbeat_for_account' do
    let(:timestamp) { Time.now }
    subject { klass.add_heartbeat_for_account(account['id'], timestamp) }

    it 'redis should have the correct members' do
      subject
      expect(Resque.redis.get('cme-heartbeat-123')).to eq timestamp.utc.iso8601.to_s
    end

    context 'when there is a resque error' do
      before { raise_redis_connection_error(:set) }

      it 'should notify honeybadger and return an error' do
        expect_errors_and_notify_honeybadger
      end
    end
  end

  describe '.add_maintenance_window_heartbeat_for_account' do
    subject { klass.add_maintenance_window_heartbeat_for_account(account['id']) }

    let(:timestamp) { Time.now }
    it 'redis should have the correct members' do
      expect(CmeFixListener::AvailabilityManager).to receive(:end_of_maintenance_window_timestamp).and_return(timestamp)
      subject
      expect(Resque.redis.get('cme-heartbeat-123')).to eq timestamp.utc.iso8601
    end

    context 'when there is a resque error' do
      before { raise_redis_connection_error(:set) }

      it 'should notify honeybadger and return an error' do
        expect_errors_and_notify_honeybadger
      end
    end
  end


  describe '.key_name' do
    subject { klass.key_name(account['id']) }

    it { expect(subject).to eq 'cme-heartbeat-123' }
  end
end
