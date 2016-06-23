# frozen_string_literal: true
require 'spec_helper'

describe SupervisionTree::MasterSupervisor do
  let(:klass) { described_class }

  context 'when creating a new master_supervisor' do
    subject { klass.start_working! }

    it 'should create two actors' do
      expect_any_instance_of(SupervisionTree::AccountsMasterSupervisor).to receive(:initialize).and_return(nil)
      expect_any_instance_of(SupervisionTree::AccountsMasterFetchActor).to receive(:speak).and_return(nil)

      container = subject
      expect(container.actors.count).to eq 3
      actor = container.actors.detect { |c| c.name == :accounts_master_supervisor }
      expect(actor.class).to eq SupervisionTree::AccountsMasterSupervisor
      actor = container.actors.detect { |c| c.name == :accounts_master_fetch_actor }
      expect(actor.class).to eq SupervisionTree::AccountsMasterFetchActor
      actor = container.actors.detect { |c| c.name == :history_request_actor }
      expect(actor.class).to eq SupervisionTree::HistoryRequestActor
    end
  end
end
