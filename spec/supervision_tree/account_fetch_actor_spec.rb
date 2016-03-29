require 'spec_helper'

describe SupervisionTree::AccountFetchActor do
  let(:klass) { described_class }
  let(:instance) { klass.new(dubbed_parent, 123) }
  let(:dubbed_parent) { double(Celluloid::Supervision::Container) }

  it 'should call speak! on init' do
    expect_any_instance_of(klass).to receive(:speak!)
    instance
  end

  describe '#speak' do
    let(:double_obj) { double(fire: nil) }

    subject { instance.speak }
    before { allow_any_instance_of(klass).to receive(:speak!).and_return(nil) }

    context 'when fetching from a config file' do
      before { ENV['FETCH_ACCOUNT_FROM_CONFIG'] = "true" }

      it 'should run every 10000 seconds when fetching from a HTTP endpoint' do
        expect_any_instance_of(klass).to receive(:every).with(10000).and_yield.and_return(double_obj)
        expect_any_instance_of(klass).to receive(:fetch_and_set_accounts)
        subject
      end
    end

    context 'when fetching from a HTTP endpoint' do
      before { ENV['FETCH_ACCOUNT_FROM_CONFIG'] = nil }

      it 'should run every 10 seconds when fetching from a HTTP endpoint' do
        expect_any_instance_of(klass).to receive(:every).with(10).and_yield.and_return(double_obj)
        expect_any_instance_of(klass).to receive(:fetch_and_set_accounts)
        subject
      end
    end
  end

  describe '#fetch_and_set_accounts' do
    subject { instance.fetch_and_set_accounts }
    before { allow_any_instance_of(klass).to receive(:speak!).and_return(nil) }

    context 'when the account fetcher successfully fetches account details' do
      let(:account_details) { {} }
      let(:dubbed_actor) { double }

      it 'should set the accounts on the parent container' do
        expect(AccountFetcher).to receive(:fetch_details_for_account_id).with(123).once.and_return(account_details)
        expect(dubbed_parent).to receive(:actors).and_return([dubbed_actor])
        expect(dubbed_actor).to receive(:async).and_return(dubbed_actor)
        expect(dubbed_actor).to receive(:set_account_details).with(account_details).once
        subject
      end
    end

    context 'when the account fetcher errors when fetching accounts' do
      let(:active_accounts) { [] }
      let(:dubbed_actor) { double }

      it 'should print the error message' do
        expect(AccountFetcher).to receive(:fetch_details_for_account_id).with(123).once.
          and_raise(StandardError.new('Network Fail'))
        expect(Honeybadger).to receive(:notify)
        subject
      end
    end
  end
end
