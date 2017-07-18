# frozen_string_literal: true

require "spec_helper"

describe CmeFixListener::HistoryRequestClient do
  let(:klass) { described_class }
  let(:instance) { klass.new({}) }
  let(:history_request_klass) { CmeFixListener::HistoryTradeCaptureReportRequester }
  let(:history_handler_klass) { CmeFixListener::HistoryResponseHandler }

  describe "#history_request!" do
    subject { instance.history_request! }

    context "when the request popped from redis is blank" do
      it "should not attempt to parse the request or request history from cme" do
        expect_any_instance_of(klass).to receive(:fetch_request_info_from_redis).and_return(nil)
        expect_any_instance_of(klass).not_to receive(:parse_request)
        expect_any_instance_of(klass).not_to receive(:request_history_from_cme)
        subject
      end
    end

    context "when the parsed request is blank" do
      it "should not attempt to request history from cme" do
        expect_any_instance_of(klass).to receive(:fetch_request_info_from_redis).and_return("bad-request")
        expect_any_instance_of(klass).to receive(:parse_request).with("bad-request").and_return(nil)
        expect_any_instance_of(klass).not_to receive(:request_history_from_cme)
        subject
      end
    end
  end

  describe "#history_request_loop" do
    let(:requester) { history_request_klass.new({}, nil, nil) }
    let(:handler) { history_handler_klass.new({}) }
    let(:response) { "cme-message-response" }

    before { allow_any_instance_of(klass).to receive(:send_request).and_return(response) }
    subject { instance.send(:history_request_loop, requester, handler) }

    context "when there are errors in the message" do
      it "should only call history_request_loop once (it should NOT make another recursive call)" do
        expect_any_instance_of(history_handler_klass).to receive(:handle_cme_response).with(response)
        expect_any_instance_of(history_handler_klass).to receive(:experiencing_problems?).and_return(true)
        expect_any_instance_of(klass).to receive(:history_request_loop).once.and_call_original
        subject
      end
    end

    context "when there is not a token present in the response" do
      it "should only call history_request_loop once (it should NOT make another recursive call)" do
        expect_any_instance_of(history_handler_klass).to receive(:handle_cme_response).with(response)
        expect_any_instance_of(history_handler_klass).to receive(:experiencing_problems?).and_return(false)
        allow_any_instance_of(history_handler_klass).to receive(:token).and_return(nil)
        expect_any_instance_of(klass).to receive(:history_request_loop).once.and_call_original
        subject
      end
    end

    context "when there is a token present in the response" do
      it "should call history_request_loop twice" do
        expect_any_instance_of(history_handler_klass).to receive(:handle_cme_response).with(response).twice
        expect_any_instance_of(history_handler_klass).to receive(:experiencing_problems?).and_return(false, false)
        allow_any_instance_of(history_handler_klass).to receive(:token).and_return("token", nil)
        expect_any_instance_of(klass).to receive(:history_request_loop).twice.and_call_original
        subject
      end
    end
  end

  describe "#send_request" do
    let(:requester) { history_request_klass.new({}, nil, nil) }

    subject { instance.send(:send_request, requester, token) }

    context "when the token is present" do
      let(:token) { "token-123" }

      it "should make an existing_client_request" do
        expect_any_instance_of(history_request_klass).to receive(:existing_client_request).with(token)
        subject
      end
    end

    context "when the token is not present" do
      let(:token) { "" }

      it "should make an existing_client_request" do
        expect_any_instance_of(history_request_klass).to receive(:new_client_request).with(nil)
        subject
      end
    end
  end

  describe "#parse_request" do
    subject { instance.send(:parse_request, request) }

    context "a good request" do
      let(:start_time) { Time.new(2016, 1, 1, 1, 0, 0) }
      let(:end_time) { Time.new(2016, 1, 1, 20, 0, 0) }
      let(:request) { { account_id: 1, start_time: start_time, end_time: end_time }.to_json }

      it "should return a hash with the account_id and iso8601 date strings" do
        subject
        expect(subject["account_id"]).to eq 1
        expect(subject["start_time"]).to eq start_time.iso8601
        expect(subject["end_time"]).to eq end_time.iso8601
      end
    end

    context "a request that cant be parsed into json" do
      let(:request) { "not-json" }

      it "should notify honeybadger and return nil" do
        expect_any_instance_of(klass).to receive(:notify_admins_of_error)
        expect(subject).to eq nil
      end
    end
  end
end
