require 'spec_helper'
require 'redis_test_helpers'

describe CmeFixListener::TokenManager do
  include RedisTestHelpers

  let(:klass) { described_class }
  let(:account) { { 'id' => 123 } }

  describe '.last_token_for_account' do
    subject { klass.last_token_for_account(account['id']) }
    before { Resque.redis.rpush('cme-token-123', '123abc') }

    it { expect(subject).to eq '123abc' }

    context 'when there is a resque error' do
      before { raise_redis_connection_error(:rpop) }

      it 'should notify honeybadger and return an error' do
        expect_errors_and_notify_honeybadger
      end
    end
  end

  describe '.add_token_for_account' do
    let(:header) { { 'token' => 'token', 'account_id' => '123' } }
    subject { klass.add_token_for_account(header) }

    it 'redis hsould have the correct members' do
      subject
      expect(Resque.redis.rpop('cme-token-123')).to eq 'token'
    end

    context 'when there is a resque error' do
      before { raise_redis_connection_error(:rpush) }

      it 'should notify honeybadger and return an error' do
        expect_errors_and_notify_honeybadger
      end
    end
  end

  describe '.key_name' do
    subject { klass.key_name(account['id']) }

    it { expect(subject).to eq 'cme-token-123' }
  end
end
