# frozen_string_literal: true

module CmeFixListener
  # If a history request is put onto redis it will request all history. When requesting history CME will return
  # TrdCaptRpts and a token (in the header). If the token is present, we must make another request as there is more
  # history to be had, if the token is blank, then we have requested all the history and we can stop.
  class HistoryRequestClient
    include ::ErrorNotifierMethods

    attr_accessor :account_hash

    def initialize(account_hash)
      puts "Creating HistoryRequestClient"
      self.account_hash = account_hash
    end

    def history_request!
      request_info = fetch_request_info_from_redis
      return unless request_info
      parsed_request = parse_request(request_info)
      return unless parsed_request
      request_history_from_cme(parsed_request)
    end

    private

    def fetch_request_info_from_redis
      CmeFixListener::HistoryRequestRedisManager.pop_request_from_queue
    end

    def parse_request(request)
      json_request = JSON.parse(request)
      if json_request["account_id"].blank?
        fail BadHistoryRequestError, "Request must include an account id, start time, and end time."
      end
      json_request["start_time"] = parsed_start_time(json_request)
      json_request["end_time"] = parsed_end_time(json_request)
      json_request
    rescue StandardError => e
      notify_admins_of_error(e, e.message, request: request, parsed_json: json_request)
      nil
    end

    def request_history_from_cme(request_info)
      requester = CmeFixListener::HistoryTradeCaptureReportRequester.new(
        account_hash, request_info["start_time"], request_info["end_time"]
      )
      response_handler = CmeFixListener::HistoryResponseHandler.new(account_hash)
      history_request_loop(requester, response_handler)
    end

    def history_request_loop(requester, handler, token = nil)
      response = send_request(requester, token)
      handler.handle_cme_response(response)
      return if handler.experiencing_problems? || handler.token.blank?
      history_request_loop(requester, handler, handler.token)
    end

    def send_request(requester, token)
      if token.present?
        requester.try(:existing_client_request, token)
      else
        requester.try(:new_client_request, nil)
      end
    end

    def parsed_start_time(json_request)
      parse_time(json_request["start_time"], default: Time.at(Time.now.to_i - 86_400))
    end

    def parsed_end_time(json_request)
      parse_time(json_request["end_time"], default: Time.now)
    end

    def parse_time(date, default:)
      Time.parse(date, default).iso8601
    end
  end
end
