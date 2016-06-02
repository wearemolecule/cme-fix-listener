module SupervisionTree
  class HistoryRequestActor
    include Celluloid

    def initialize(_parent_containter)
      puts 'Creating HistoryRequestActor'
      speak!
    end

    def speak!
      async.speak
    end

    def speak
      every(timeout) do
        request_info = fetch_request_info_from_redis
        if request_info.present?
          request_history_from_cme(request_info)
        end
      end.fire
    end

    def fetch_request_info_from_redis
      CmeFixListener::HistoryRequestRedisManager.pop_request_from_queue
    end

    def request_history_from_cme(request_info)
          puts 'Found Request!!!!!'
      puts request_info
      puts request_info['account_id']
      account_details = AccountFetcher.fetch_details_for_account_id(request_info['account_id'])
      puts 'Account Dets!!!!!'
      puts account_details
      return
      start_time = request_info['start_time']
      end_time = request_info['end_time']

      @requester = CmeFixListener::HistoryTradeCaptureReportRequester.new(account_details, start_time, end_time)
      @response_handler = CmeFixListener::HistoryResponseHandler.new(account_details)
      history_request_loop
    end

    def history_request_loop(token = nil)
      response = send_request(token)
      @response_handler.handle_cme_response(response)
      if !@response_handler.experiencing_problems? && @response_handler.token.present?
        history_request_loop(@response_handler.token)
      end
    end

    def send_request(token)
      if token.present?
        @requester.existing_client_request(token)
      else
        @requester.new_client_request(nil)
      end
    end

    def timeout
      timeout = ENV['HISTORY_POLLING_INTERVAL_IN_SECONDS']
      if timeout.blank?
        300
      else
        timeout.to_i
      end
    end
  end
end
