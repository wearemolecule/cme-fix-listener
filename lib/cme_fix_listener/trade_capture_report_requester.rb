# frozen_string_literal: true

module CmeFixListener
  # Make HTTP requests to CME.
  # Given the username, password, and url from the account it will POST to CME with the correct header and body.
  # If the requests fails it will retry twice and then bail.
  class TradeCaptureReportRequester
    DEFAULT_CME_HOST = "https://posttrade.api.cmegroup.com"
    PLAIN_TEXT_HEADER = { "Content-Type" => "text/plain", "Accept-Encoding" => "gzip, deflate" }.freeze

    include HTTParty

    attr_accessor :account, :username, :password, :url, :request_generator

    def initialize(account)
      @account = account
      @username = account["cmeUsername"]
      @password = account["cmePassword"]
      @request_generator = CmeFixListener::RequestGenerator.new(account)
      @base_options = { basic_auth: { username: @username, password: @password } }
    end

    def new_client_request(_token)
      post_client_request("1", PLAIN_TEXT_HEADER)
    end

    def existing_client_request(token)
      post_client_request("3", PLAIN_TEXT_HEADER.merge("x-cme-token" => token))
    end

    private

    def post_client_request(type, header)
      attempts ||= 2
      Logging.logger.debug do
        [
          "Posting request to CME",
          type, cme_url, header, request_body(type)
        ]
      end
      response = post_http_request(request_body(type), header)
      Logging.logger.debug { response }
      response
    rescue Net::ReadTimeout
      Logging.logger.debug { "Request Timeout, retrying" }
      configurable_sleep
      retry unless (attempts -= 1).zero?
    end

    def configurable_sleep
      sleep ENV["SLEEP_INTERVAL"].present? ? ENV["SLEEP_INTERVAL"].to_i : 5
    end

    def post_http_request(body, header)
      return if body.blank?
      self.class.post(cme_url, @base_options.merge(body: body, headers: header))
    end

    def request_body(request_type)
      @request_generator.build_xml(request_type)
    end

    def cme_url
      "#{cme_host}/cmestp/query"
    end

    def cme_host
      ENV.fetch("CME_HOST", DEFAULT_CME_HOST)
    end
  end
end
