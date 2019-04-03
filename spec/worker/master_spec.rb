# frozen_string_literal: true

require "spec_helper"

describe Worker::Master do
  describe "#fetch_active_accounts!" do
    it "should return an array of hashes" do
      expect(AccountFetcher).to receive(:fetch_active_accounts).and_return(
        [{ "id" => 1 }, { "id" => 2 }]
      )
      expect(AccountFetcher).to receive(:fetch_details_for_account_id).with(1).and_return(
        "id" => 1, "name" => "Account1"
      )
      expect(AccountFetcher).to receive(:fetch_details_for_account_id).with(2).and_return(
        "id" => 2, "name" => "Account2"
      )

      accounts = Worker::Master.new.send(:fetch_active_accounts!)

      expect(accounts).to eq [
        { "id" => 1, "name" => "Account1" },
        { "id" => 2, "name" => "Account2" }
      ]
    end

    it "should returned cached accounts if the lookup fails" do
      logger = double("some logger").as_null_object
      allow(Logging).to receive(:logger).and_return(logger)

      worker = Worker::Master.new
      worker.active_accounts = [{ "id" => 1, "name" => "Account1" }]
      expect(AccountFetcher).to receive(:fetch_active_accounts).and_raise(RuntimeError)

      accounts = worker.send(:fetch_active_accounts!)

      expect(accounts).to eq [{ "id" => 1, "name" => "Account1" }]
    end
  end
end
