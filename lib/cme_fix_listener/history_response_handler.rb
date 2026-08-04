# frozen_string_literal: true

module CmeFixListener
  # Handles CME responses in a manor suitable for history requests
  class HistoryResponseHandler < ResponseHandler
    # History pagination keeps the token in memory only; do not advance the live
    # poll cursor in Redis.
    def commit_parsed_response(parsed_headers, parsed_body, raw_headers)
      handle_headers(parsed_headers, raw_headers)
      handle_body(parsed_body)
    end

    def handle_headers(parsed_headers, _raw_headers)
      Logging.logger.debug { parsed_headers }
      @token = parsed_headers["token"]
    end

    def body_error_message
      "CME response had errors when requesting history for account id #{account_id}"
    end
  end
end
