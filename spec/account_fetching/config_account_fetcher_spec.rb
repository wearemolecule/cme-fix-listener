require 'spec_helper'

describe HttpAccountFetcher do
  let(:klass) { described_class }
  let(:account) { { 'id' => 123, 'name' => 'Account1' } }

  before do
    expect(HTTParty).to receive(:get).with(host).and_return(json_message)
    ENV['ACCOUNT_HTTP_HOST'] = "http://account-service:8080"
  end

  describe '.fetch_details_for_account_id' do
    let(:host) { "http://account-service:8080/account/#{account['id']}/cme_details"}

    subject { klass.fetch_details_for_account_id(account['id']) }

    context 'when valid JSON is returned' do
      let(:json_message) do
        double(body:
        {
          "id": 123,
          "name": "Account1",
          "cmeIntegrationActive": true,
          "cmeUsername": "username",
          "cmePassword": "password",
          "cmeEnvironment": "Testing",
          "cmeFirmSid": "your-company-name",
          "cmePartyRole": "7",
          "cmeRequestID": "your-company-name"
        }.to_json)
      end

      it { expect(subject).to eq json_message.body }
    end

    context 'when there are not any active accounts' do
      let(:json_message) { double(body: [].to_json) }

      it { expect(subject).to eq json_message.body }
    end
  end

  describe '.fetch_active_accounts' do
    let(:host) { "http://account-service:8080/accounts?cmeIntegrationActive=true" }

    subject { klass.fetch_active_accounts }

    context 'when there is valid JSON in the config file' do
      let(:json_message) do
        double(body:
               [
                 {
                   "id": 123,
                   "name": "Account1",
                   "cmeIntegrationActive": true,
                   "cmeUsername": "username",
                   "cmePassword": "password",
                   "cmeEnvironment": "Testing",
                   "cmeFirmSid": "your-company-name",
                   "cmePartyRole": "7",
                   "cmeRequestID": "your-company-name"
                 },
                 {
                   "id": "account2_id",
                   "name": "account2_name",
                   "cmeIntegrationActive": true,
                   "cmeUsername": "username",
                   "cmePassword": "password",
                   "cmeEnvironment": "Testing",
                   "cmeFirmSid": "your-company-name",
                   "cmePartyRole": "7",
                   "cmeRequestID": "your-company-name"
                 }
        ].to_json)
      end

      it { expect(subject).to eq json_message.body }
    end

    context 'when the file does not exist' do
      let(:json_message) { double(body: [].to_json) }

      it { expect(subject).to eq json_message.body }
    end
  end
end
