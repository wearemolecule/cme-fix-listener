# frozen_string_literal: true
require 'spec_helper'

describe CmeFixListener::Client do
  let(:klass) { described_class }
  let(:requester_klass) { CmeFixListener::TradeCaptureReportRequester }
  let(:responder_klass) { CmeFixListener::ResponseHandler }

  let(:instance) { klass.new(account) }
  let(:account) { { 'id' => 123, 'name' => 'Account1' } }

  describe '#establish_session!' do
    before do
      expect_any_instance_of(responder_klass).to receive(:experiencing_problems?).and_return(problems)
    end
    subject { instance.establish_session! }

    context 'when experiencing problems' do
      let(:problems) { true }

      it 'should not attempt to login to cme' do
        expect_any_instance_of(klass).not_to receive(:make_request!)
        expect_any_instance_of(klass).not_to receive(:log_heartbeat)
        subject
      end
    end

    context 'when not experiencing problems' do
      let(:problems) { false }

      it 'should attempt to login to cme' do
        expect_any_instance_of(klass).to receive(:make_request!)
        expect_any_instance_of(klass).to receive(:log_heartbeat)
        subject
      end
    end
  end

  describe '#make_request!' do
    before do
      expect_any_instance_of(klass).to receive(:last_token_for_account).and_return(token)
    end

    subject { instance.make_request! }

    context 'when a new client' do
      let(:token) { nil }

      it 'should listen for a subscription response using request type 1' do
        expect_any_instance_of(klass).to receive(:new_client_request)
        expect_any_instance_of(klass).not_to receive(:existing_client_request)
        subject
      end
    end

    context 'when an existing client' do
      let(:token) { '123' }

      it 'should listen for a subscription response using request type 3' do
        expect_any_instance_of(klass).not_to receive(:new_client_request)
        expect_any_instance_of(klass).to receive(:existing_client_request)
        subject
      end
    end

    context 'when there is an error retrieving token' do
      let(:token) { { errors: 'Redis connect error' } }

      it 'should listen for a subscription response using request type 3' do
        expect_any_instance_of(klass).not_to receive(:new_client_request)
        expect_any_instance_of(klass).not_to receive(:existing_client_request)
        subject
      end
    end
  end

  describe '#last_token_for_account' do
    subject { instance.last_token_for_account }

    it 'should call out to TokenManager' do
      expect(CmeFixListener::TokenManager).to receive(:last_token_for_account).with(account['id'])
      subject
    end
  end

  describe '#log_hearbeat' do
    subject { instance.log_heartbeat }

    it 'should call out to HeartbeatManager' do
      expect(CmeFixListener::HeartbeatManager).to receive(:add_heartbeat_for_account)
      subject
    end
  end

  describe '#new_client_request' do
    let(:response) { 'NRSP' }

    subject { instance.new_client_request }

    it 'should make the correct calls' do
      expect_any_instance_of(requester_klass).to receive(:new_client_request).with(nil).and_return(response)
      expect_any_instance_of(responder_klass).to receive(:handle_cme_response).with(response)
      subject
    end
  end

  describe '#existig_client_request' do
    let(:response) { 'ERSP' }
    let(:token) { 'token' }

    subject { instance.existing_client_request(token) }

    it 'should make the correct calls' do
      expect_any_instance_of(requester_klass).to receive(:existing_client_request).with(token).and_return(response)
      expect_any_instance_of(responder_klass).to receive(:handle_cme_response).with(response)
      subject
    end
  end
end
