# frozen_string_literal: true
module CmeFixListener
  # Initiates request to CME and pushes the response along.
  # This class will tell TradeCaptureReportRequest either make a new or continued request to CME,
  # depending on a token existing for the account. Once the request is made, the response is pushed to ResponseHandler.
  class Client
    attr_accessor :account, :requester, :response_handler

    def initialize(account)
      @account = account
      @requester = CmeFixListener::TradeCaptureReportRequester.new(account)
      @response_handler = CmeFixListener::ResponseHandler.new(account)
    end

    def establish_session!
      return if @response_handler.experiencing_problems?
      make_request!
      log_heartbeat
    end

    def make_request!
      token = last_token_for_account
      return if token.present? && token.try(:dig, :errors).present?
      if token.present?
        existing_client_request(token)
      else
        new_client_request
      end
    end

    def last_token_for_account
      CmeFixListener::TokenManager.last_token_for_account(account['id'])
    end

    def new_client_request
      puts 'Attempting to Authenticate with CME as a new subscription'
      send_request(:new_client_request)
    end

    def existing_client_request(token)
      puts 'Attempting to Authenticate with CME as a continued subscription'
      send_request(:existing_client_request, token)
    end

    def send_request(request_type, token = nil)
      cme_response = @requester.send(request_type, token)
      @response_handler.handle_cme_response(cme_response)
    end

    def log_heartbeat
      CmeFixListener::HeartbeatManager.add_heartbeat_for_account(account['id'], Time.now)
    end
  end
end
