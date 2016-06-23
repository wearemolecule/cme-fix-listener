# frozen_string_literal: true
class BadAccountDataFetched < StandardError; end

module SupervisionTree
  # Celluliod actor to initiate CME requests
  # Every request interval (integer set as an environment variable) it will ask CmeFixListener::AvailabilityManager
  # if it inside the CME operating window (times found in AvailabilityManager).
  # If so, this actor will tell CmeFixListener::Client to make a request to CME.
  # If not, there will be no request made.
  class CmeFixListenerActor
    include Celluloid
    include ::ErrorNotifierMethods

    attr_accessor :account_id, :account, :request_interval, :paused

    def initialize(_parent_container, account_id)
      puts "Creating CmeFixListenerActor for #{account_id}"
      @account_id = account_id
      @account = nil
      @request_interval = ENV['REQUEST_INTERVAL'].present? ? ENV['REQUEST_INTERVAL'].to_i : 10
      @paused = false
      start_requests!
    end

    # rubocop:disable AccessorMethodName
    # Called from a different actor inside its parent container
    # Sets account data fetched from the AccountFetchActor
    def set_account_details(account_details)
      if account_details['id'] != account_id
        notify_admins_of_error(BadAccountDataFetched,
                               error_message(account_id, account_details),
                               error_context(account_id, account_details))
      else
        @account = account_details
      end
    end
    # rubocop:enable AccessorMethodName

    def start_requests!
      async.start_requests
    end

    def start_requests
      every(@request_interval) { async.async_make_request }
    end

    def async_make_request
      if inside_operating_window?
        resume_requests
        log_resume_requests
      else
        CmeFixListener::HeartbeatManager.add_maintenance_window_heartbeat_for_account(account_id)
        log_pause_requests
        sleep_before_next_attempted_login
      end
    end

    # Check uptime_manager.rb for CME maintenance window.
    # Once CME goes down it won't come back up for some time, sleeping here prevents unneeded processing.
    def sleep_before_next_attempted_login
      sleep 900
    end

    def inside_operating_window?
      CmeFixListener::AvailabilityManager.available?(current_time)
    end

    def current_time
      Time.now.in_time_zone('Central Time (US & Canada)')
    end

    def resume_requests
      return if @account.nil?
      client = CmeFixListener::Client.new(@account)
      client.establish_session!
    end

    def log_resume_requests
      return unless @paused
      @paused = false
      puts "#{current_time} is within the availability window. Resuming..."
    end

    def log_pause_requests
      return if @paused
      @paused = true
      puts "#{current_time} is not within the availability window. Pausing..."
    end

    def error_message(account_id, account_details)
      "Account ID is #{account_id} and Fetched data is #{account_details}"
    end

    def error_context(account_id, account_details)
      { details: "Previous account_id: #{account_id} does not match the new account_id: #{account_details['id']}" }
    end
  end
end
