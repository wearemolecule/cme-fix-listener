# frozen_string_literal: true

require "spec_helper"
require "redis_test_helpers"

describe CmeFixListener::HistoryRequestRedisManager do
  include RedisTestHelpers

  describe ".pop_request_from_queue", redis: true do
    let(:account1) { "300" }
    let(:account2) { "301" }
    before do
      Resque.redis.rpush("cme-history-request-#{account1}", "guitar")
      Resque.redis.rpush("cme-history-request-#{account2}", "drums")
    end
    after(:each) { Resque.redis.redis.flushall }

    it "gets from the right queue" do
      expect(described_class.pop_request_from_queue(account1)).to eq "guitar"
      expect(described_class.pop_request_from_queue(account2)).to eq "drums"
    end

    context "when there is a resque error" do
      it "should notify honeybadger and return an error" do
        raise_redis_connection_error(:rpop)
        expect_errors_and_notify_honeybadger
        described_class.pop_request_from_queue("NONE")
      end
    end
  end
end
