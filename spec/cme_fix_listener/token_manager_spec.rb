# frozen_string_literal: true

require "spec_helper"
require "redis_test_helpers"

describe CmeFixListener::TokenManager do
  include RedisTestHelpers

  let(:account) { { "id" => 123 } }

  describe ".last_token_for_account", redis: true do
    subject { described_class.last_token_for_account(account["id"]) }
    before { Resque.redis.rpush("cme-token-123", "123abc") }

    it { expect(subject).to eq "123abc" }

    context "when there is a resque error" do
      before { raise_redis_connection_error(:rpop) }

      it "should notify honeybadger and return an error" do
        expect_errors_and_notify_honeybadger
      end
    end
  end

  describe ".add_token_for_account", redis: true do
    let(:header) { { "token" => "token", "account_id" => "123" } }
    subject { described_class.add_token_for_account(header) }

    it "redis hsould have the correct members" do
      subject
      expect(Resque.redis.rpop("cme-token-123")).to eq "token"
    end

    context "when there is a resque error" do
      before { raise_redis_connection_error(:rpush) }

      it "should notify honeybadger and return an error" do
        expect_errors_and_notify_honeybadger
      end
    end
  end

  describe ".clear_token_for_account", redis: true do
    subject { described_class.clear_token_for_account(account["id"]) }
    before { Resque.redis.rpush("cme-token-123", "123abc") }

    it "removes the token from redis" do
      subject
      expect(Resque.redis.rpop("cme-token-123")).to be_nil
    end

    context "when there is a resque error" do
      before { raise_redis_connection_error(:del) }

      it "should notify honeybadger and return an error" do
        expect_errors_and_notify_honeybadger
      end
    end
  end

  describe ".key_name", redis: true do
    subject { described_class.key_name(account["id"]) }

    it { expect(subject).to eq "cme-token-123" }
  end
end
