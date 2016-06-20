# frozen_string_literal: true
module SupervisionTree
  # Accounts Master celluloid supervisor.
  # This supervisor monitors active CME accounts. For every active CME account this will create an AccountSupervisor.
  # If a new account is turned on this supervisor will create another AccountSupervisor and add it to the group of
  # supervisors it is monitoring. This supervisor will also remove AccountSupervisor actors for accounts that have
  # been turned off.
  class AccountsMasterSupervisor
    include Celluloid

    attr_accessor :active_account_ids, :accounts_master_container

    def initialize(_parent_container)
      puts 'Creating AccountsMasterSupervisor'
      @active_account_ids = []
      @accounts_master_container = Celluloid::Supervision::Container.run!
    end

    # rubocop:disable AccessorMethodName
    # Called from a different actor inside its parent container
    # Sets the active cme accounts from the AccountsFetchActor.
    def set_active_accounts(active_accounts)
      new_account_ids, deleted_account_ids = account_ids_diff(active_accounts)
      puts "Found new accounts: #{new_account_ids}"
      puts "Found deleted accounts: #{deleted_account_ids}"
      create_secondary_supervisors(new_account_ids)
      remove_secondary_supervisors(deleted_account_ids)
    end
    # rubocop:enable AccessorMethodName

    def account_ids_diff(active_accounts)
      fetched_active_account_ids = active_accounts.map { |account| account['id'] }
      new_account_ids = fetched_active_account_ids.reject { |id| @active_account_ids.include?(id) }
      deleted_account_ids = @active_account_ids.reject { |id| fetched_active_account_ids.include?(id) }
      [new_account_ids, deleted_account_ids]
    end

    def create_secondary_supervisors(new_account_ids)
      new_account_ids.each do |account_id|
        @accounts_master_container.add(configuration(AccountSupervisor,
                                                     account_supervisor_name(account_id),
                                                     account_id))
      end
      @active_account_ids = (@active_account_ids + new_account_ids).uniq
    end

    def remove_secondary_supervisors(deleted_account_ids)
      deleted_account_ids.each do |account_id|
        actor_name = account_supervisor_name(account_id)
        # An actor which is a Celluloid::Supervision::Container does not remove its own actors.
        find_actor(actor_name).destroy!
        @accounts_master_container.remove(actor_name)
        @active_account_ids.delete(account_id)
      end
    end

    private

    def account_supervisor_name(account_id)
      "account_#{account_id}_supervisor".to_sym
    end

    def find_actor(actor_name)
      @accounts_master_container.actors.detect { |a| a.name == actor_name }
    end

    def configuration(group, name, account_id)
      {
        type: group,
        as: name,
        args: [account_id]
      }
    end
  end
end
