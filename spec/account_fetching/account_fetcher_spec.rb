# frozen_string_literal: true
require 'spec_helper'

describe AccountFetcher do
  let(:klass) { described_class }
  let(:http_klass) { HttpAccountFetcher }
  let(:config_klass) { ConfigAccountFetcher }

  describe '.fetch_details_for_account_id' do
    let(:id) { 123 }

    subject { klass.fetch_details_for_account_id(id) }

    context 'using a config file fetcher' do
      before { ENV['FETCH_ACCOUNT_FROM_CONFIG'] = 'true' }
      it do
        expect(config_klass).to receive(:fetch_details_for_account_id).with(id).and_return(nil)
        subject
      end
    end

    context 'using a http fetcher' do
      before { ENV['FETCH_ACCOUNT_FROM_CONFIG'] = nil }
      it do
        expect(http_klass).to receive(:fetch_details_for_account_id).with(id).and_return(nil)
        subject
      end
    end
  end

  describe '.fetch_active_accounts' do
    subject { klass.fetch_active_accounts }

    context 'using a config file fetcher' do
      before { ENV['FETCH_ACCOUNT_FROM_CONFIG'] = 'true' }
      it do
        expect(config_klass).to receive(:fetch_active_accounts).and_return(nil)
        subject
      end
    end

    context 'using a HTTP fetcher' do
      before { ENV['FETCH_ACCOUNT_FROM_CONFIG'] = nil }
      it do
        expect(http_klass).to receive(:fetch_active_accounts).and_return(nil)
        subject
      end
    end
  end

  describe '.parse_json' do
    subject { klass.parse_json(response, invalid_return_object) }

    context 'when there is valid JSON' do
      let(:response) { { 'name' => 123 }.to_json }
      let(:invalid_return_object) { {} }
      it { expect(subject).to eq JSON.parse(response) }
    end

    context 'when there is not valid JSON' do
      let(:response) { {} }
      let(:invalid_return_object) { [] }
      it { expect(subject).to eq invalid_return_object }
    end
  end

  describe '.account_fetcher_klass' do
    subject { klass.account_fetcher_klass }

    context 'using a config fetcher' do
      before { ENV['FETCH_ACCOUNT_FROM_CONFIG'] = 'true' }
      it { expect(subject).to eq config_klass }
    end

    context 'using a http fetcher' do
      before { ENV['FETCH_ACCOUNT_FROM_CONFIG'] = nil }
      it { expect(subject).to eq http_klass }
    end
  end
end
