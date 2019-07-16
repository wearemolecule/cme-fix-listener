# frozen_string_literal: true

module CmeFixListener
  # Handles CME responses in a manor suitable for history requests
  class HistoryResponseHandler < ResponseHandler
    def handle_headers(parsed_headers, _raw_headers)
      @token = parsed_headers["token"]
    end

    def body_error_message
      "CME response had errors when requesting history for account id #{account_id}"
    end
  end
end
