# frozen_string_literal: true

module CmeFixListener
  # Make HTTP requests to CME.
  # Given the username, password, and url from the account it will POST to CME with the correct header and body.
  # If the requests fails it will retry twice and then bail.
  class TradeCaptureReportRequester
    include HTTParty

    attr_accessor :account, :username, :password, :url, :request_generator

    def initialize(account)
      @account = account
      @username = account["cmeUsername"]
      @password = account["cmePassword"]
      @environment = account["cmeEnvironment"]
      @request_generator = CmeFixListener::RequestGenerator.new(account)
    end

    def new_client_request(_token)
      post_client_request("1", plain_text_header)
    end

    def existing_client_request(token)
      post_client_request("3", token_header(token))
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
      HTTParty.post(cme_url, base_options.merge(body: body, headers: header))
    end

    def request_body(request_type)
      @request_generator.build_xml(request_type)
    end

    def cme_url
      if @environment.casecmp("production").zero?
        "https://posttrade.api.cmegroup.com/cmestp/query"
      else
        "https://posttrade.api.uat.cmegroup.com/cmestp/query"
      end
    end

    def base_options
      {
        basic_auth: {
          username: @username,
          password: @password
        }
      }
    end

    def plain_text_header
      {
        "Content-Type" => "text/plain",
        "Accept-Encoding" => "gzip, deflate"
      }
    end

    def token_header(token)
      plain_text_header.merge("x-cme-token" => token)
    end
  end
end
