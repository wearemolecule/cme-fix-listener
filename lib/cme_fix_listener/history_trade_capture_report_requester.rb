# frozen_string_literal: true

module CmeFixListener
  # Make HISTORY HTTP requests to CME.
  # Given the username, password, and url from the account it will POST to CME with the correct header and body.
  # If the requests fails it will retry twice and then bail.
  class HistoryTradeCaptureReportRequester < TradeCaptureReportRequester
    def initialize(account, start_time, end_time)
      super(account)
      @request_generator = CmeFixListener::HistoryRequestGenerator.new(account, start_time, end_time)
    end
  end
end
