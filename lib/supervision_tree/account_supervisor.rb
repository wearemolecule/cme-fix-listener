# frozen_string_literal: true
module SupervisionTree
  # Account celluloid supervisor.
  # This supervisor creates and monitors two actors, CmeLooperActor and AccountFetchActor.
  class AccountSupervisor
    include Celluloid
    include ::Logging

    attr_accessor :account_id, :container

    def initialize(account_id)
      @account_id = account_id
      create
    end

    def create
      Logging.logger.info { "Creating AccountSupervisor for account id: #{@account_id}" }
      @container = Celluloid::Supervision::Container.run!
      @container.add(configuration(SupervisionTree::CmeFixListenerActor,
                                   actor_name(SupervisionTree::CmeFixListenerActor)))
      @container.add(configuration(SupervisionTree::AccountFetchActor,
                                   actor_name(SupervisionTree::AccountFetchActor)))
    end

    # Called before this Actor is terminated. Termination does not do any cleanup so it should terminate its own actors.
    def destroy!
      Logging.logger.info { "Destroying AccountSupervisor for account id: #{@account_id}" }
      @container.remove(actor_name(SupervisionTree::CmeFixListenerActor))
      @container.remove(actor_name(SupervisionTree::AccountFetchActor))
    end

    private

    def actor_name(actor_class)
      "#{actor_class.name.demodulize.underscore}_#{@account_id}".to_sym
    end

    def configuration(actor, name)
      {
        type: actor,
        as: name,
        args: [@container, @account_id]
      }
    end
  end
end
