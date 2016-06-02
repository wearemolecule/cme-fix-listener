module CmeFixListener
  class HistoryTradeCaptureReportRequester < TradeCaptureReportRequester
    def initialize(account, start_time, end_time)
      super(account)
      @request_generator = CmeFixListener::HistoryRequestGenerator.new(account, start_time, end_time)
    end
  end
end
