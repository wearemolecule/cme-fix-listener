module CmeFixListener
  # Make HTTP requests to CME.
  # Given the username, password, and url from the account it will POST to CME with the correct header and body.
  # If the requests fails it will retry twice and then bail.
  class TradeCaptureReportRequester
    include HTTParty

    attr_accessor :account, :username, :password, :url, :request_generator

    def initialize(account)
      @account = account
      @username = account['cmeUsername']
      @password = account['cmePassword']
      @environment = account['cmeEnvironment']
      @request_generator = CmeFixListener::RequestGenerator.new(account)
    end

    def new_client_request(_token)
      post_client_request('1', plain_text_header)
    end

    def existing_client_request(token)
      post_client_request('3', token_header(token))
    end

    private

    def post_client_request(type, header)
      attempts ||= 2
      post_http_request(request_body(type), header)
    rescue Net::ReadTimeout
      configurable_sleep
      retry unless (attempts -= 1).zero?
    end

    def configurable_sleep
      sleep ENV['SLEEP_INTERVAL'].present? ? ENV['SLEEP_INTERVAL'].to_i : 5
    end

    def post_http_request(body, header)
      return if body.blank?
      HTTParty.post(cme_url, base_options.merge(body: body, headers: header))
    end

    def request_body(request_type)
      @request_generator.build_xml(request_type)
    end

    def cme_url
      if @environment.casecmp('production').zero?
        'https://services.cmegroup.com/cmestp/query'
      else
        'https://servicesnr.cmegroup.com/cmestp/query'
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
        'Content-Type' => 'text/plain'
      }
    end

    def token_header(token)
      {
        'Content-Type' => 'text/plain',
        'x-cme-token' => token
      }
    end
  end
end
