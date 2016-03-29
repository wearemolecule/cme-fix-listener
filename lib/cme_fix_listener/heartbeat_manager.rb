module CmeFixListener
  # Creates and adds a list, on redis, named 'cme-heartbeat-#{account_id}' for each active account id.
  # This 'heartbeat' is meant to be consumed by another service to determine if the cme-fix-listener is alive.
  class HeartbeatManager < RedisManager

    def self.add_heartbeat_for_account(account_id, timestamp)
      catch_errors('set') do
        Resque.redis.set(key_name(account_id), timestamp.utc.iso8601)
      end
    end

    def self.add_maintenance_window_heartbeat_for_account(account_id)
      catch_errors('set') do
        timestamp = CmeFixListener::AvailabilityManager.end_of_maintenance_window_timestamp(Time.now).utc.iso8601
        Resque.redis.set(key_name(account_id), timestamp)
      end
    end

    def self.key_name(account_id)
      "cme-heartbeat-#{account_id}"
    end

    def self.error_context
      { class: 'HeartbeatManager' }
    end
  end
end
