# frozen_string_literal: true

module CmeFixListener
  # Provides methods to pop requests off of the cme-history-request redis queue.
  class HistoryRequestRedisManager < RedisManager
    def self.pop_request_from_queue(account_id)
      catch_errors("pop") do
        Resque.redis.rpop(key_name(account_id))
      end
    end

    def self.key_name(account_id)
      "cme-history-request-#{account_id}"
    end

    def self.error_context
      { class: "HistoryRequestManager" }
    end
  end
end
