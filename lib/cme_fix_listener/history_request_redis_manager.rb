module CmeFixListener
  class HistoryRequestRedisManager < RedisManager
    def self.pop_request_from_queue
      catch_errors('pop') do
        Resque.redis.rpop(key_name)
      end
    end

    def self.key_name
      "cme-history-request"
    end

    def self.error_context
      { class: 'HistoryRequestManager' }
    end
  end
end
