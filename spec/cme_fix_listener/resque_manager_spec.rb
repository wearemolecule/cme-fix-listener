# frozen_string_literal: true

require "spec_helper"

describe CmeFixListener::ResqueManager do
  let(:account_id) { 123 }
  let(:token) { "cme-token-abc" }
  let(:msg) { [{ "tradeId" => "1" }].to_json }
  let(:queue_name) { "critical" }
  let(:class_name) { "CmeTrdCaptRptMsg" }

  around do |example|
    old_queue = ENV["REDIS_QUEUE_NAME"]
    old_class = ENV["REDIS_CLASS_NAME"]
    ENV["REDIS_QUEUE_NAME"] = queue_name
    ENV["REDIS_CLASS_NAME"] = class_name
    example.run
  ensure
    ENV["REDIS_QUEUE_NAME"] = old_queue
    ENV["REDIS_CLASS_NAME"] = old_class
  end

  describe ".persist_token_and_enqueue" do
    it "writes the token and queue item inside a single Redis MULTI" do
      expect(Resque.redis).to receive(:multi).and_yield.and_return([])
      expect(Resque.redis).to receive(:rpush).with("cme-token-123", token).ordered
      expect(Resque.redis).to receive(:sadd).with("queues", queue_name).ordered
      expect(Resque.redis).to receive(:rpush).with(
        "queue:#{queue_name}",
        described_class.enqueue_item(account_id, msg)
      ).ordered

      described_class.persist_token_and_enqueue(account_id, token, msg)
    end

    it "advances the token without enqueueing when the message is blank" do
      expect(Resque.redis).to receive(:multi).and_yield.and_return([])
      expect(Resque.redis).to receive(:rpush).once.with("cme-token-123", token)
      expect(Resque.redis).not_to receive(:sadd)

      described_class.persist_token_and_enqueue(account_id, token, nil)
    end

    context "with a real Redis MULTI/EXEC", redis: true do
      before { Resque.redis.redis.flushall }
      after { Resque.redis.redis.flushall }

      it "commits the token and trade batch together" do
        described_class.persist_token_and_enqueue(account_id, token, msg)

        expect(Resque.redis.rpop("cme-token-123")).to eq token
        expect(Resque.redis.smembers("queues")).to include(queue_name)
        expect(Resque.redis.rpop("queue:#{queue_name}")).to eq described_class.enqueue_item(account_id, msg)
      end

      it "does not advance the token when work fails inside MULTI before EXEC" do
        call_count = 0
        allow(Resque.redis).to receive(:rpush).and_wrap_original do |original, *args|
          call_count += 1
          raise Redis::CannotConnectError if call_count > 1
          original.call(*args)
        end

        expect {
          described_class.persist_token_and_enqueue(account_id, token, msg)
        }.to raise_error(Redis::CannotConnectError)

        expect(Resque.redis.lindex("cme-token-123", 0)).to be_nil
        expect(Resque.redis.llen("queue:#{queue_name}")).to eq 0
      end
    end
  end

  describe ".enqueue" do
    it "pushes the item onto the configured queue" do
      expect(Resque.redis).to receive(:sadd).with("queues", queue_name)
      expect(Resque.redis).to receive(:rpush).with(
        "queue:#{queue_name}",
        described_class.enqueue_item(account_id, msg)
      )

      described_class.enqueue(account_id, msg)
    end
  end
end
