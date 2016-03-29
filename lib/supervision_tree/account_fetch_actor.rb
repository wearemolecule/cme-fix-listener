module SupervisionTree
  # Account detail fetching celluloid actor.
  # Every 10 (or 1000 if reading from a config file) seconds this actor will call the AccountFetcher to fetch account details
  # for its given account (passed in during initalization). The data is then put on the CmeFixListenerActor.
  class AccountFetchActor
    include Celluloid
    include ::ErrorNotifierMethods

    attr_accessor :parent_container, :account_id

    def initialize(parent_container, account_id)
      @parent_container = parent_container
      @account_id = account_id
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
      account_details = AccountFetcher.fetch_details_for_account_id(@account_id)
      puts "Fetched account details for account id #{@account_id} \n\n #{account_details}"
      @parent_container.actors.first.async.set_account_details(account_details)
    rescue StandardError => e
      notify_admins_of_error(e, error_message(e), error_context)
    end

    def error_message(e)
      "Error fetching account details: #{e.message}"
    end

    def error_context
      { account_id: @account_id }
    end

    # If we are polling a HTTP endpoint for account information it makes sense to ask for updates frequently.
    # But, if we are reading in account information from a file on the repo, we don't need to poll at all. In lieu of
    # rewritting the supervision-tree, a very long timeout will basically acheive the same thing.
    def timeout
      if ENV['FETCH_ACCOUNT_FROM_CONFIG'].present?
        10000
      else
        10
      end
    end
  end
end
