# frozen_string_literal: true

require "spec_helper"
require "redis_test_helpers"

describe CmeFixListener::HistoryRequestRedisManager do
  include RedisTestHelpers

  let(:klass) { described_class }

  describe ".pop_request_from_queue", redis: true do
    subject { klass.pop_request_from_queue }
    before { Resque.redis.rpush("cme-history-request", "testing123") }
    after(:each) { Resque.redis.flushall }

    it { expect(subject).to eq "testing123" }

    context "when there is a resque error" do
      before { raise_redis_connection_error(:rpop) }

      it "should notify honeybadger and return an error" do
        expect_errors_and_notify_honeybadger
      end
    end
  end

  describe ".key_name", redis: true do
    subject { klass.key_name }

    it { expect(subject).to eq "cme-history-request" }
  end
end
