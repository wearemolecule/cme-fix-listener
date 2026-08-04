# frozen_string_literal: true

module CmeFixListener
  # Given a queue name, class name, and object it will add the queue to redis,
  # and then publish the object to the given class name (within the queue).
  class ResqueManager
    def self.enqueue(account_id, msg)
      push(enqueue_item(account_id, msg))
    end

    # Persist the CME poll cursor (token) and optionally enqueue the trade batch
    # in a single Redis MULTI/EXEC so a crash cannot advance the cursor without
    # durably queuing the messages from that poll.
    def self.persist_token_and_enqueue(account_id, token, msg = nil)
      Resque.redis.multi do
        Resque.redis.rpush(TokenManager.key_name(account_id), token)
        push(enqueue_item(account_id, msg)) if msg.present?
      end
    end

    def self.enqueue_item(account_id, msg)
      {
        "class" => ENV["REDIS_CLASS_NAME"],
        "args" => [account_id, msg]
      }.to_json
    end

    def self.push(item)
      Resque.redis.sadd("queues", ENV["REDIS_QUEUE_NAME"])
      Resque.redis.rpush("queue:#{ENV['REDIS_QUEUE_NAME']}", item)
    end
  end
end
