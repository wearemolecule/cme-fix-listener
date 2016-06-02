module SupervisionTree
  # Master celluloid supervisor.
  # A single master supervisor to monitor the actor that fetches account data and the supervisor that monitors the
  # individual account actors. This serves as the head of the celluloid supervision tree.
  # See celluloid supervision documentation for more information on celluliod supervision groups.
  class MasterSupervisor
    def self.start_working!
      create!
    end

    def self.create!
      puts 'Creating MasterSupervisor'
      master_container = Celluloid::Supervision::Container.run!
      master_container.add(configuration(SupervisionTree::AccountsMasterSupervisor,
                                         :accounts_master_supervisor,
                                         master_container))
      master_container.add(configuration(SupervisionTree::AccountsMasterFetchActor,
                                         :accounts_master_fetch_actor,
                                         master_container))
      master_container.add(configuration(SupervisionTree::HistoryRequestActor,
                                         :history_request_actor,
                                         master_container))
    end

    def self.configuration(group, name, container)
      {
        type: group,
        as: name,
        args: [container]
      }
    end
  end
end
