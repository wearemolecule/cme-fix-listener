# frozen_string_literal: true
class BadHistoryRequestError < StandardError; end

module SupervisionTree
  # If a history request is put onto redis it will request all history. When requesting history CME will return
  # TrdCaptRpts and a token (in the header). If the token is present, we must make another request as there is more
  # history to be had, if the token is blank, then we have requested all the history and we can stop.
  class HistoryRequestActor
    include Celluloid
    include ::ErrorNotifierMethods

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
          parsed_request = parse_request(request_info)
          request_history_from_cme(parsed_request) if parsed_request.present?
        end
      end.fire
    end

    def fetch_request_info_from_redis
      CmeFixListener::HistoryRequestRedisManager.pop_request_from_queue
    end

    def request_history_from_cme(request_info)
      account_details = AccountFetcher.fetch_details_for_account_id(request_info['account_id'])
      start_time = request_info['start_time']
      end_time = request_info['end_time']

      requester = CmeFixListener::HistoryTradeCaptureReportRequester.new(account_details, start_time, end_time)
      response_handler = CmeFixListener::HistoryResponseHandler.new(account_details)
      history_request_loop(requester, response_handler)
    end

    def history_request_loop(requester, handler, token = nil)
      response = send_request(requester, token)
      handler.handle_cme_response(response)
      if !handler.experiencing_problems? && handler.token.present?
        history_request_loop(requester, handler, handler.token)
      end
    end

    def send_request(requester, token)
      if token.present?
        requester.try(:existing_client_request, token)
      else
        requester.try(:new_client_request, nil)
      end
    end

    def parse_request(request)
      json_request = JSON.parse(request)
      if json_request['account_id'].blank?
        fail BadHistoryRequestError, 'Request must include an account id, start time, and end time.'
      end
      json_request['start_time'] = parsed_start_time(json_request)
      json_request['end_time'] = parsed_end_time(json_request)
      json_request
    rescue StandardError => e
      notify_admins_of_error(e, e.message, request: request, parsed_json: json_request)
    end

    def parsed_start_time(json_request)
      parse_time(json_request['start_time'], default: Time.at(Time.now.to_i - 86_400))
    end

    def parsed_end_time(json_request)
      parse_time(json_request['end_time'], default: Time.now)
    end

    def parse_time(date, default:)
      Time.parse(date, default).iso8601
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
