# frozen_string_literal: true
module SupervisionTree
  # Master celluloid supervisor.
  # A single master supervisor to monitor the actor that fetches account data and the supervisor that monitors the
  # individual account actors. This serves as the head of the celluloid supervision tree.
  # See celluloid supervision documentation for more information on celluliod supervision groups.
  class MasterSupervisor
    include ::Logging

    def self.start_working!
      create!
    end

    def self.create!
      Logging.logger.info { 'Creating MasterSupervisor' }
      master_container = Celluloid::Supervision::Container.run!
      master_container.add(config(SupervisionTree::AccountsMasterSupervisor,
                                  :accounts_master_supervisor, master_container))
      master_container.add(config(SupervisionTree::AccountsMasterFetchActor,
                                  :accounts_master_fetch_actor, master_container))
      master_container.add(config(SupervisionTree::HistoryRequestActor, :history_request_actor, master_container))
    end

    def self.config(group, name, container)
      {
        type: group,
        as: name,
        args: [container]
      }
    end
  end
end
