# frozen_string_literal: true
module SupervisionTree
  # Active CME Account fetch celluloid actor
  # Every 10 seconds this actor will call the AccountFetcher to fetch all active CME accounts.
  # It will put that data on the AccountsMasterSupervisor.
  class AccountsMasterFetchActor
    include Celluloid
    include ::ErrorNotifierMethods

    attr_accessor :parent_container

    def initialize(parent_container)
      @parent_container = parent_container
      speak!
    end

    def speak!
      async.speak
    end

    def speak
      every(timeout) do
        fetch_and_set_accounts
      end.fire
    end

    def fetch_and_set_accounts
      accounts = AccountFetcher.fetch_active_accounts
      puts "Fetched active CME accounts: \n\n #{accounts}"
      @parent_container.actors.first.async.set_active_accounts(accounts)
    rescue StandardError => e
      notify_admins_of_error(e, error_message(e), error_context)
    end

    def error_message(e)
      "Error fetching active accounts: #{e.message}"
    end

    def error_context
      { class: 'AccountsMasterFetchActor' }
    end

    # If we are polling a HTTP endpoint for account information it makes sense to ask for updates frequently.
    # But, if we are reading in account information from a file on the repo, we don't need to poll at all. In lieu of
    # rewritting the supervision-tree, a very long timeout will basically acheive the same thing.
    def timeout
      if ENV['FETCH_ACCOUNT_FROM_CONFIG']
        10_000
      else
        10
      end
    end
  end
end
