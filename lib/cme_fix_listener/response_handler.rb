# frozen_string_literal: true
class TokenNotFound < StandardError; end
class CmeResponseHasErrors < StandardError; end
module CmeFixListener
  # Pushes a parsed response to ResqueManager.
  # Given the CME response this class will parse the response body into JSON and send the JSON to ResqueManager.
  # If there are any errors in the response body they will be logged.
  # CME also sends a token through the response header, this class will also add that token to the account through
  # the TokenManager.
  class ResponseHandler
    include ErrorNotifierMethods

    attr_accessor :account, :account_id, :invalid_credentials, :token

    def initialize(account)
      puts "Creating ResponseHandler for #{account['id']}"
      @account = account
      @account_id = account['id']
      @body_has_errors = false
      @token = nil
    end

    def experiencing_problems?
      @body_has_errors
    end

    def handle_cme_response(cme_response)
      parsed_headers = parse_headers(cme_response.headers)
      handle_headers(parsed_headers, cme_response.headers)
      parsed_body = parse_body(cme_response.body)
      handle_body(parsed_body)
    end

    def parse_headers(headers)
      {
        'token' => headers['x-cme-token'],
        'account_id' => @account_id,
        'created_at' => headers['date']
      }
    end

    def handle_headers(parsed_headers, raw_headers)
      if parsed_headers['token'].blank?
        notify_admins_of_error(TokenNotFound, header_error_message, header_error_context(raw_headers, parsed_headers))
      else
        CmeFixListener::TokenManager.add_token_for_account(parsed_headers)
      end
    end

    def parse_body(body)
      parser = CmeFixListener::FixmlParser.new(body)
      return handle_error(parser, body) if body_has_errors?(parser)
      parser.parse_fixml
    end

    def handle_body(parsed_body)
      return if parsed_body.blank?
      CmeFixListener::ResqueManager.enqueue(@account_id, parsed_body.to_json)
    end

    def handle_error(parser, body)
      notify_admins_of_error(CmeResponseHasErrors, body_error_message, body_error_context(parser, body))
      @body_has_errors = true
      nil
    end

    def body_has_errors?(parser)
      parser.request_acknowledgement_text.present?
    end

    def raw_body_message(body)
      format(%(
        Raw CME Message from request at #{Time.now.utc} (UTC):
        %s
      ), [body])
    end

    def full_error_message(error_text, body)
      puts printf(%(
        Error Estimation: %s
        - Account: %s
        - Body: %s
      ), estimate_error_message(error_text), @account, body)
    end

    def estimate_error_message(error_txt)
      error_text = error_txt.downcase
      return not_entitled_error_message if not_entitled?(error_text)
      return does_not_belong_to_error_message if does_not_belong_to?(error_text)
      return authentication_failed_error_message if authentication_failed?(error_text)
      return query_error_message if query_error?(error_text)
      'Unable to estimate error'
    end

    def header_error_message
      "Token not found in CME response for account id #{account_id}"
    end

    def header_error_context(raw_headers, parsed_headers)
      { raw_headers: raw_headers.to_hash, parsed_headers: parsed_headers }
    end

    def body_error_message
      "CME response has errors for account id #{account_id}"
    end

    def body_error_context(parser, body)
      { error_message: full_error_message(parser.request_acknowledgement_text, body) }
    end
  end
end
