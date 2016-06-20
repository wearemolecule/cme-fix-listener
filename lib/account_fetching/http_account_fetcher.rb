# frozen_string_literal: true
# Fetches account information.
# Given a host name (found in ENV) it has the ability to perform a GET request to to retrieve all CME
# active accounts or cme details of an account, given an id.
class HttpAccountFetcher < AccountFetcher
  def self.fetch_details_for_account_id(account_id)
    HTTParty.get("#{host}/account/#{account_id}/cme_details").body
  end

  def self.fetch_active_accounts
    HTTParty.get("#{host}/accounts?cmeIntegrationActive=true").body
  end

  def self.host
    ENV['ACCOUNT_HTTP_HOST']
  end
end
