# frozen_string_literal: true
require 'spec_helper'

describe SupervisionTree::AccountsMasterSupervisor do
  let(:klass) { described_class }
  let(:instance) { klass.new(nil) }
  let(:dubbed_container) { double(Celluloid::Supervision::Container) }

  before(:each) { expect(Celluloid::Supervision::Container).to receive(:run!).and_return(dubbed_container) }

  describe '#set_active_accounts' do
    subject { instance.set_active_accounts([]) }

    context 'when there are new active accounts' do
      let(:returned_ids) { [[1, 2, 3], []] }

      it 'should create an AccountSupervisor for each new active account' do
        expect_any_instance_of(klass).to receive(:account_ids_diff).with([]).and_return(returned_ids)
        expect(dubbed_container).to receive(:add).exactly(3).times
        subject
        expect(instance.active_account_ids).to eq [1, 2, 3]
      end
    end

    context 'when given no new active accounts' do
      let(:returned_ids) { [[], []] }

      it 'should not create or delete any AccountSupervisors' do
        expect_any_instance_of(klass).to receive(:account_ids_diff).with([]).and_return(returned_ids)
        expect(dubbed_container).not_to receive(:add)
        expect(dubbed_container).not_to receive(:remove)
        subject
        expect(instance.active_account_ids).to eq []
      end
    end

    context 'when active accounts are turned off' do
      let(:returned_ids) { [[], [1, 2]] }
      let(:dubbed_actor1) { double(name: :account_1_supervisor) }
      let(:dubbed_actor2) { double(name: :account_2_supervisor) }
      let(:dubbed_actors) { [dubbed_actor1, dubbed_actor2] }

      it 'should delete the AccountSupervisors associated with the newly inactive accounts' do
        expect_any_instance_of(klass).to receive(:account_ids_diff).with([]).and_return(returned_ids)
        expect(dubbed_container).to receive(:remove).twice
        expect(dubbed_container).to receive(:actors).twice.and_return(dubbed_actors)
        expect(dubbed_actor1).to receive(:destroy!).once
        expect(dubbed_actor2).to receive(:destroy!).once
        subject
        expect(instance.active_account_ids).to eq []
      end
    end
  end

  # Newly active account ids are fetched accounts that have not been seen before.
  # Newly inactive account ids are fetched accounts that have been seen before but are no longer present in the active
  # accounts list.
  describe '#account_ids_diff' do
    subject { instance.account_ids_diff(active_accounts) }
    before { instance.active_account_ids = current_account_ids }

    context 'when only given new active accounts' do
      let(:active_accounts) { [{ 'id' => 1 }, { 'id' => 2 }] }
      let(:current_account_ids) { [1] }

      it 'should return the new account ids without any deleted ids' do
        expect(subject).to eq [[2], []]
      end
    end

    context 'when only given newly inactive accounts' do
      let(:active_accounts) { [{ 'id' => 1 }] }
      let(:current_account_ids) { [1, 2] }

      it 'should return the deleted account ids without any new ids' do
        expect(subject).to eq [[], [2]]
      end
    end

    context 'when there are no newly active or inactive accounts' do
      let(:active_accounts) { [{ 'id' => 1 }] }
      let(:current_account_ids) { [1] }

      it 'should return no new account ids or no deleted account ids' do
        expect(subject).to eq [[], []]
      end
    end

    context 'when given both newly active account ids and newly inactive account ids' do
      let(:active_accounts) { [{ 'id' => 1 }] }
      let(:current_account_ids) { [0] }

      it 'should return the newly active account ids and newly inactive account ids' do
        expect(subject).to eq [[1], [0]]
      end
    end
  end
end
