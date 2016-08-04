# frozen_string_literal: true
# Fetches account information.
# Given an env var "FETCH_ACCOUNT_FROM_CONFIG" it will decided to fetch account details from an
# HTTP endpoint or from a config file. It will then call out to the correct fetchers and return parsed JSON
# from those fetchers.
class AccountFetcher
  include Logging

  def self.fetch_details_for_account_id(account_id)
    parse_json(account_fetcher_klass.fetch_details_for_account_id(account_id), {})
  end

  def self.fetch_active_accounts
    parse_json(account_fetcher_klass.fetch_active_accounts, [])
  end

  def self.parse_json(response, invalid_json_return_object)
    JSON.parse(response)
  rescue StandardError
    Logging.logger.error { "Unable to parse JSON: #{response}" }
    invalid_json_return_object
  end

  def self.account_fetcher_klass
    if ENV['FETCH_ACCOUNT_FROM_CONFIG']
      ConfigAccountFetcher
    else
      HttpAccountFetcher
    end
  end
end
