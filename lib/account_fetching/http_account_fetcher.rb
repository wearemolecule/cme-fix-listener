# frozen_string_literal: true

# Fetches account information.
# Given a host name (found in ENV) it has the ability to perform a GET request to to retrieve all CME
# active accounts or cme details of an account, given an id.
class HttpAccountFetcher < AccountFetcher
  include ::Logging

  def self.fetch_details_for_account_id(account_id)
    retry_if_failed(account_id) do
      HTTParty.get("#{host}/account/#{account_id}/cme_details").body
    end
  end

  def self.fetch_active_accounts
    retry_if_failed do
      HTTParty.get("#{host}/accounts?cmeIntegrationActive=true").body
    end
  end

  def self.retry_if_failed(account_id = nil)
    retries ||= 0
    yield
  rescue Errno::ECONNRESET => e
    raise e unless (retries += 1) < 3
    Logging.logger.error { "Unable to fetch account details for #{account_id}, error: #{e.message}" }
    sleep_before_retry(30)
    retry
  end

  def self.sleep_before_retry(nsecs)
    sleep(nsecs)
  end

  def self.host
    ENV["ACCOUNT_HTTP_HOST"]
  end
end
