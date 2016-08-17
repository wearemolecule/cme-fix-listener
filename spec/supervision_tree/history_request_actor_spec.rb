# frozen_string_literal: true
require 'spec_helper'

describe SupervisionTree::HistoryRequestActor do
  let(:klass) { described_class }
  let(:instance) { klass.new(dubbed_parent) }
  let(:dubbed_parent) { double(Celluloid::Supervision::Container) }
  let(:history_request_klass) { CmeFixListener::HistoryTradeCaptureReportRequester }
  let(:history_handler_klass) { CmeFixListener::HistoryResponseHandler }

  it 'should call speak! on init' do
    expect_any_instance_of(klass).to receive(:speak!)
    instance
  end

  describe '#speak' do
    let(:double_obj) { double(fire: nil) }

    subject { instance.speak }
    before { allow_any_instance_of(klass).to receive(:speak!).and_return(nil) }

    context 'when polling env var is set' do
      before { ENV['HISTORY_POLLING_INTERVAL_IN_SECONDS'] = '10' }

      it 'it should run every env var interval' do
        expect_any_instance_of(klass).to receive(:every).with(10).and_yield.and_return(double_obj)
        expect_any_instance_of(klass).to receive(:fetch_request_info_from_redis).and_return(nil)
        subject
      end
    end

    context 'when polling env var is not set' do
      before { ENV['HISTORY_POLLING_INTERVAL_IN_SECONDS'] = '' }

      it 'it should run every 300 seconds' do
        expect_any_instance_of(klass).to receive(:every).with(300).and_yield.and_return(double_obj)
        expect_any_instance_of(klass).to receive(:fetch_request_info_from_redis)
        subject
      end
    end

    context 'when the request popped from redis is blank' do
      it 'should not attempt to parse the request or request history from cme' do
        expect_any_instance_of(klass).to receive(:every).with(300).and_yield.and_return(double_obj)
        expect_any_instance_of(klass).to receive(:fetch_request_info_from_redis).and_return(nil)
        expect_any_instance_of(klass).not_to receive(:parse_request)
        expect_any_instance_of(klass).not_to receive(:request_history_from_cme)
        subject
      end
    end

    context 'when the parsed request is blank' do
      it 'should not attempt to request history from cme' do
        expect_any_instance_of(klass).to receive(:every).with(300).and_yield.and_return(double_obj)
        expect_any_instance_of(klass).to receive(:fetch_request_info_from_redis).and_return('bad-request')
        expect_any_instance_of(klass).to receive(:parse_request).with('bad-request').and_return(nil)
        expect_any_instance_of(klass).not_to receive(:request_history_from_cme)
        subject
      end
    end
  end

  describe '#history_request_loop' do
    let(:requester) { history_request_klass.new({}, nil, nil) }
    let(:handler) { history_handler_klass.new({}) }
    let(:response) { 'cme-message-response' }

    subject { instance.history_request_loop(requester, handler) }

    before do
      allow_any_instance_of(klass).to receive(:speak!).and_return(nil)
      allow_any_instance_of(klass).to receive(:send_request).and_return(response)
    end

    context 'when there are errors in the message' do
      it 'should only call history_request_loop once (it should NOT make another recursive call)' do
        expect_any_instance_of(history_handler_klass).to receive(:handle_cme_response).with(response)
        expect_any_instance_of(history_handler_klass).to receive(:experiencing_problems?).and_return(true)
        expect_any_instance_of(klass).to receive(:history_request_loop).once.and_call_original
        subject
      end
    end

    context 'when there is not a token present in the response' do
      it 'should only call history_request_loop once (it should NOT make another recursive call)' do
        expect_any_instance_of(history_handler_klass).to receive(:handle_cme_response).with(response)
        expect_any_instance_of(history_handler_klass).to receive(:experiencing_problems?).and_return(false)
        allow_any_instance_of(history_handler_klass).to receive(:token).and_return(nil)
        expect_any_instance_of(klass).to receive(:history_request_loop).once.and_call_original
        subject
      end
    end

    context 'when there is a token present in the response' do
      it 'should call history_request_loop twice' do
        expect_any_instance_of(history_handler_klass).to receive(:handle_cme_response).with(response).twice
        expect_any_instance_of(history_handler_klass).to receive(:experiencing_problems?).and_return(false, false)
        allow_any_instance_of(history_handler_klass).to receive(:token).and_return('token', nil)
        expect_any_instance_of(klass).to receive(:history_request_loop).twice.and_call_original
        subject
      end
    end
  end

  describe '#send_request', redis: true do
    let(:requester) { history_request_klass.new({}, nil, nil) }

    subject { instance.send_request(requester, token) }

    context 'when the token is present' do
      let(:token) { 'token-123' }

      it 'should make an existing_client_request' do
        expect_any_instance_of(history_request_klass).to receive(:existing_client_request).with(token)
        subject
      end
    end

    context 'when the token is not present' do
      let(:token) { '' }

      it 'should make an existing_client_request' do
        expect_any_instance_of(history_request_klass).to receive(:new_client_request).with(nil)
        subject
      end
    end
  end

  describe '#parse_request', redis: true do
    subject { instance.parse_request(request) }

    context 'a good request' do
      let(:start_time) { Time.new(2016, 1, 1, 1, 0, 0) }
      let(:end_time) { Time.new(2016, 1, 1, 20, 0, 0) }
      let(:request) { { account_id: 1, start_time: start_time, end_time: end_time }.to_json }

      it 'should return a hash with the account_id and iso8601 date strings' do
        subject
        expect(subject['account_id']).to eq 1
        expect(subject['start_time']).to eq start_time.iso8601
        expect(subject['end_time']).to eq end_time.iso8601
      end
    end

    context 'a request that cant be parsed into json' do
      let(:request) { 'not-json' }

      it 'should notify honeybadger and return nil' do
        expect_any_instance_of(klass).to receive(:notify_admins_of_error)
        expect(subject).to eq nil
      end
    end
  end
end
