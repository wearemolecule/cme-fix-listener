module CmeFixListener
  # Creates and adds a list, on redis, named 'cme-token-#{account_id}' for each active account id.
  class TokenManager < RedisManager

    def self.last_token_for_account(account_id)
      catch_errors('pop') do
        Resque.redis.rpop(key_name(account_id))
      end
    end

    def self.add_token_for_account(header)
      catch_errors('push') do
        Resque.redis.rpush(key_name(header['account_id']), header['token'])
      end
    end

    def self.key_name(account_id)
      "cme-token-#{account_id}"
    end

    def self.error_context
      { class: 'TokenManager' }
    end
  end
end
