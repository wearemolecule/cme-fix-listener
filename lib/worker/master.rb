# frozen_string_literal: true

module Worker
  # The Master Worker is the entrypoint to trade capture. The single 'work!' method will block continuously.
  class Master
    include ::ErrorNotifierMethods
    include ::Logging

    attr_accessor :active_accounts

    def initialize
      Logging.logger.info { "Creating Worker::Master" }
      @paused = false
      @active_accounts = []
    end

    # work is a blocking method. The 'fetch' and 'pause' methods have custom timeouts and are implemented
    # in each method.
    def work!
      loop do
        if inside_operating_window?
          fetch
          check_for_history_request
        else
          pause
        end
        log_activity
      end
    end

    private

    def fetch
      elapsed = elapsed_time do
        fetch_active_accounts!.map do |account_hash|
          Thread.new do
            fetch_trades_for_account!(account_hash)
            Thread.current.exit
          end
        end.map(&:join)
      end

      sleep_before_next_trade_capture(elapsed)
    end

    def check_for_history_request
      fetch_active_accounts!.map do |account_hash|
        Thread.new do
          CmeFixListener::HistoryRequestClient.new(account_hash).history_request!
          Thread.current.exit
        end
      end.map(&:join)

      sleep_before_next_history_request
    end

    def pause
      return if @paused
      fetch_active_accounts!.map do |account_hash|
        Thread.new { CmeFixListener::HeartbeatManager.add_maintenance_window_heartbeat_for_account(account_hash["id"]) }
      end.map(&:join)

      sleep_before_next_attempted_login
    end

    def log_activity
      if inside_operating_window? && @paused
        @paused = false
        Logging.logger.info { "#{current_time} is within the availability window. Resuming..." }
      elsif !inside_operating_window? && !@paused
        @paused = true
        Logging.logger.info { "#{current_time} is not within the availability window. Pausing..." }
      end
    end

    # Fetch active CME accounts.
    #
    # We should save the active accounts each fetch so if any subsequent fetch fails we can return the cache.
    # To fetch the relevant data we need to make 2 requests: 1) Active IDs 2) Account Details.
    def fetch_active_accounts!
      accounts = AccountFetcher.fetch_active_accounts.map do |account_hash|
        Thread.new { AccountFetcher.fetch_details_for_account_id(account_hash["id"]) }
      end.map(&:join).map(&:value)
      @active_accounts = accounts
      accounts
    rescue => e
      notify_admins_of_error(e, "Error fetching active accounts: #{e.message}", nil)
      @active_accounts
    end

    # Fetch trades for account.
    #
    # We should catch all errors so errors fetch trades for any single account doesn't affect any other account.
    def fetch_trades_for_account!(account_hash)
      CmeFixListener::Client.new(account_hash).establish_session!
    rescue => e
      notify_admins_of_error(e, "Error fetching trades for #{account_hash['id']}: #{e.message}", nil)
      nil
    end

    # CME goes down for maintenance. See the AvailabilityManager docs for more info.
    def inside_operating_window?
      CmeFixListener::AvailabilityManager.available?(current_time)
    end

    def current_time
      Time.now.in_time_zone("Central Time (US & Canada)")
    end

    def sleep_before_next_trade_capture(n = 0)
      wait = ENV["REQUEST_INTERVAL"].present? ? ENV["REQUEST_INTERVAL"].to_i : 10
      wait = (wait - n).positive? ? wait - n : 0
      sleep wait
    end

    # Once CME goes into maintenance it won't come back up for a while, sleeping prevents unneeded processing.
    def sleep_before_next_attempted_login
      sleep 900
    end

    def sleep_before_next_history_request
      sleep 60
    end

    def elapsed_time
      now = Time.now
      yield if block_given?
      Time.now.to_i - now.to_i
    end
  end
end
