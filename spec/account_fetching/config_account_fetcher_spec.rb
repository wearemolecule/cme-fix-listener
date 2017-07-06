# frozen_string_literal: true

require "spec_helper"

describe ConfigAccountFetcher do
  let(:klass) { described_class }
  let(:account) { { "id" => 123, "name" => "Account1" } }

  before(:each) { expect(klass).to receive(:config_file_path).and_return(file_path) }

  describe ".fetch_details_for_account_id" do
    subject { klass.fetch_details_for_account_id(account["id"]) }

    context "when there is valid JSON in the config file" do
      let(:file_path) { "spec/datafiles/account-config.json" }

      it "should correctly parse the JSON" do
        expect(subject).to eq(
          {
            "id" => 123,
            "name" => "Account1",
            "cmeIntegrationActive" => true,
            "cmeUsername" =>  "username",
            "cmePassword" =>  "password",
            "cmeEnvironment" => "Testing",
            "cmeFirmSid" =>  "your-company-name",
            "cmePartyRole" =>  "7",
            "cmeRequestID" =>  "your-company-name"
          }.to_json
        )
      end
    end

    context "when there is NOT valid JSON in the config file" do
      let(:file_path) { "spec/datafiles/account-config-bad.json" }

      it { expect(subject).to eq nil }
    end

    context "when the file does not exist" do
      let(:file_path) { "spec/datafiles/account-config1.json" }

      it { expect(subject).to eq nil }
    end
  end

  describe ".fetch_active_accounts" do
    subject { klass.fetch_active_accounts }

    context "when there is valid JSON in the config file" do
      let(:file_path) { "spec/datafiles/account-config.json" }

      it "should correctly parse the JSON" do
        expect(subject).to eq File.read(file_path)
      end
    end

    context "when there is NOT valid JSON in the config file" do
      let(:file_path) { "spec/datafiles/account-config-bad.json" }

      it { expect(subject).to eq File.read(file_path) }
    end

    context "when the file does not exist" do
      let(:file_path) { "spec/datafiles/account-config1.json" }

      it { expect(subject).to eq nil }
    end
  end
end
